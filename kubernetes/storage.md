# Storage

Because the homelab operates on a single physical device, the ideal solution is to utilize the storage available in the hypervisor host.
- This avoids unnecessary data replication and write amplification

## Storage options

- NFS server + [NFS provisioner](https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner)
	- Slow IO
- [Proxmox CSI plugin](https://github.com/sergelogvinov/proxmox-csi-plugin)
	- Require clustering proxmox nodes
	- Require correct labeling of kubernetes
		- Excessive coupling of hypervisor and kubernetes configuration
	- Require VM `SCSI Controller` set to `VirtIO SCSI | VirtIO SCSI Single`
	- Require Proxmox API token
- ZFS + [Democratic CSI](https://github.com/democratic-csi/democratic-csi) using iSCSI
	- Require root SSH connection
		- Can also use user with passwordless sudo for ZFS related commands
- [Ceph](https://ceph.io/en/) / [Longhorn](https://longhorn.io/) / [OpenEBS](https://openebs.io/)
	- Operates on distributed storage arrays with replication
		- Great for resilliency if physically distinct storage
		- IO amplification if virtualized on same physical disk
	- CPU / memory overhead

Democratic CSI was chosen for the following reasons:
- Decouple hypervisor and kubernetes
- Minimal overhead for single disk host

## Configuring Democratic CSI

### Configuring connection

Democratic CSI only provides a helm chart.
- Receives connection credentials as input
- Helm cannot inject references to kubernetes secret
	- Requires the application chart to cooperate
	- Argo CD refuses to support injecting secrets into helm charts
		- https://github.com/argoproj/argo-cd/issues/1786
		- https://github.com/argoproj/argo-cd/issues/4041
		- https://github.com/argoproj/argo-cd/issues/5202
		- https://github.com/argoproj/argo-cd/issues/12060
- Democratic CSI documentation does not state whether it supports referencing kubernetes secrets
	- Eventually found the [official chart repo's example](https://github.com/democratic-csi/charts/blob/master/stable/democratic-csi/values.yaml) which shows it can reference existing kubernetes config

Democratic CSI shows the following [special configuration required for Talos nodes](https://github.com/democratic-csi/democratic-csi?tab=readme-ov-file#talos) (at the time of writing)
```yaml
node:
  hostPID: true
  driver:
    extraEnv:
      - name: ISCSIADM_HOST_STRATEGY
        value: nsenter
      - name: ISCSIADM_HOST_PATH
        value: /usr/local/sbin/iscsiadm
    iscsiDirHostPath: /usr/local/etc/iscsi  # <--- This is outdated and must be set to `/var/iscsi`
    iscsiDirHostPathType: ""
```

`node.driver.iscsiDirHostPath` must be updated to match [changes in Talos](https://github.com/siderolabs/extensions/issues/688) but the instructions have not been updated for more than 2 months despite the [relevant issue](https://github.com/democratic-csi/democratic-csi/issues/461) being closed

`csiDriver.name` must also be a valid lowercase RFC 1123 subdomain, which neither the comments in the example config nor the linked references mention.
- After deploying, Argo CD shows the reason in its error log

Although some reference links for configuring ZFS iSCSI on linux has been provided, it would have been nice if the minimum requirements were written explicitly.  
In addition, iSCSI tpg attributes must be set manually since configuration defined in kubernetes do not apply retroactively to existing resources.
```bash
# Name should be 17 chars or less
zfs create "$ZPOOL/$DATASET"
apt install -y targetcli-fb
targetcli <<EOF
cd /iscsi
create $IQN_BASENAME
exit
EOF
```

### Stable ZVol naming

The `driver.iscsi.nameTemplate` option only applies within iSCSI (`targetcli ls /backstores/block`) and not the actual ZVol created (`zfs list -t volume`).  
By default, the CSI uses the `name` attribute set by Kubernetes.  
This happens to be the name of the persistent volume, which has the format `pvc-{uuid}`

PV names are not stable, so if the entire kubernetes cluster is recreated, it would fail to reattach to the existing ZVol.  
This is disadvantagous for restoring from backup since the PV would always create a new volume and restoring on a busy device may lead to data corruption. It also tightly couples the storage state with kubernetes state, making it harder to rebuild the kubernetes cluster from the repository.

Thus begins the hunt for predictable ZVol naming.

The `targetcli` command used to provision new ZVols is in `src/driver/controller-zfs-generic/index.js` [here](https://github.com/democratic-csi/democratic-csi/blob/3974268272a84e9c22c47cae2fca847a8d422bad/src/driver/controller-zfs-generic/index.js#L108-L306)

```sh
# create target
cd /iscsi
create ${basename}:${assetName}
# ...
# create extent
cd /backstores/block
create ${assetName} /dev/${extentDiskName}
# ...
# add extent to target/tpg
cd /iscsi/${basename}:${assetName}/tpg1/luns
create /backstores/block/${assetName}
```

There are 3 `create` commands, which depend on `basename, assetName, extentDiskName`. The relevant snippets are shown below.

```js
async createShare(call, datasetName) {
	// ...

	case "zfs-generic-iscsi": {
		let basename;
		let assetName;

		if (this.options.iscsi.nameTemplate) {
			assetName = Handlebars.compile(this.options.iscsi.nameTemplate)({
			name: call.request.name,
			parameters: call.request.parameters,
			});
		}

		// ...

		let extentDiskName = "zvol/" + datasetName;

		switch (this.options.iscsi.shareStrategy) {
			case "targetCli":
				basename = this.options.iscsi.shareStrategyTargetCli.basename;
```

Since `iscsi.nameTemplate` only showed an effect within targetcli, `extentDiskName` must be the ZVol name, which is passed in as an argument.

Searching for the call site reveals `src/driver/controller-zfs/index.js` [here](https://github.com/democratic-csi/democratic-csi/blob/3974268272a84e9c22c47cae2fca847a8d422bad/src/driver/controller-zfs/index.js#L639-L1295) with the relevant snippets below.

```js
async CreateVolume(call) {
	const driver = this;
	// ...
	let datasetParentName = this.getVolumeParentDatasetName();
	// ...
	let volume_id = await driver.getVolumeIdFromCall(call);
	// ...
	const datasetName = datasetParentName + "/" + volume_id;
	// ...
	volume_context = await this.createShare(call, datasetName);
```

It is obvious `volume_id` is the ZVol name, which is obtained from `src/driver/index.js` [here](https://github.com/democratic-csi/democratic-csi/blob/3974268272a84e9c22c47cae2fca847a8d422bad/src/driver/index.js#L448-L551)

```js
async getVolumeIdFromCall(call) {
	const driver = this;
	let volume_id = call.request.name;
	// ...
	const idTemplate = _.get(
		driver.options,
		"_private.csi.volume.idTemplate",
		""
	);
	if (idTemplate) {
		volume_id = Handlebars.compile(idTemplate)({
			name: call.request.name,
			parameters: call.request.parameters,
		});
	// ...
	const hash_strategy = _.get(
		driver.options,
		"_private.csi.volume.idHash.strategy",
		""
	);
```

The snippet above reveals 2 undocumented driver config options:
- `_private.csi.volume.idTemplate`
- `_private.csi.volume.idHash.strategy`

In order to create a valid template, it is necessary to know what parameters are available.  
The [CSI docs](https://kubernetes-csi.github.io/docs/external-provisioner.html#persistentvolumeclaim-and-persistentvolume-parameters) list the following parameters:
- csi.storage.k8s.io/pvc/name
	- Statefulset PVC name format: {volumeClaimTemplates name}-{StatefulSet name}-{ordinal}
- csi.storage.k8s.io/pvc/namespace
- csi.storage.k8s.io/pv/name
    - UUID based for dynamically provisioned PV

## Afterthoughts

Deploying stateful apps via kubernetes sucks when the app is not designed to be clustered
- Only 1 concurrent instance can be running
	- Shared storage results in race condition corrupting data
	- Separate storage is not automatically reconciled
- Slow IO or failover
	- NFS or distributed storage has higher IO overhead
	- Block storage does not support ReadWriteMany
		- Existing connection must be terminated before a new node can establish connection

For homelab with centralized storage, it would be ideal to establish a node on the storage server dedicated to stateful applications only and use [local volumes](https://kubernetes.io/docs/concepts/storage/volumes/#local)
