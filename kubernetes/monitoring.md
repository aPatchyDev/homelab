# Monitoring

Prometheus was chosen as it seems to be the de-facto standard for monitoring.

Configuration can be reloaded via `kubectl exec -n prometheus app-0 -- kill -SIGHUP 1`
- [Reference](https://prometheus.io/docs/prometheus/latest/getting_started/#reloading-configuration)

## Storage Monitoring

As mentioned in [../host_setup/README.md](../host_setup/README.md), I wanted to monitor ZFS ARC cache hit rate.

Proxmox can push metrics to an external server, although [documentation on what data is included is lacking](pve.proxmox.com/wiki/External_Metric_Server).  
Based on some existing Grafana dashboards ([1](https://grafana.com/grafana/dashboards/13307-proxmox-ve/), [2](https://grafana.com/grafana/dashboards/10048-proxmox/), [3](https://grafana.com/grafana/dashboards/24550-proxmox-ve-pve-exporter/)) the metrics for ZFS does not seem to include what I wanted to track:
- ZFS cache hit rate
- Disk S.M.A.R.T. status

Since I intend to use Prometheus for monitoring other workloads, I opted to using prometheus exporters.  
ZFS metrics can be obtained from the host system via [Node Exporter](https://prometheus.io/docs/guides/node-exporter/) which is available as a [debian package](https://github.com/prometheus-community/smartctl_exporter).  
Disk S.M.A.R.T metrics can be obtained from the host system via [Smartctl Exporter](https://github.com/prometheus-community/smartctl_exporter) although this is [only packaged for Debian Sid](https://pkgs.org/download/prometheus-smartctl-exporter) and would require installation outside the system package manager as of now.

## Migration to Kube-Prometheus-Stack

Migrated for better kubernetes integration.

Due to changes in naming scheme and mount locations, the new instance created a separate volume. As a result, data from the old instance had to be migrated.

Direct zvol copy did not work due to differences in mount point.
- Old instance based on docker defaults: store data at volume root and mount to correct location
- New instance: store data at /prometheus-db/

After re-creating the new instance's volume, I used a temporary container to copy files from one volume to the other.
- `kubectl [apply | destroy] -f <name of yaml file below>`

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: migration
  namespace: prometheus
spec:
  containers:
  - name: migration
    image: alpine
    command: ["/bin/sh", "-c", "sleep 3600"]
    volumeMounts:
    - name: old-vol
      mountPath: /mnt/old
    - name: new-vol
      mountPath: /mnt/new
  volumes:
  - name: old-vol
    persistentVolumeClaim:
      claimName: <old prometheus data volume>
  - name: new-vol
    persistentVolumeClaim:
      claimName: <new prometheus data volume>
```

The directory structure inside the migration container was as follows:

```
# tree /mnt
/mnt
├── new
│   ├── lost+found
│   └── prometheus-db
│       ├── chunks_head/
│       ├── lock
│       ├── queries.active
│       └── wal/
└── old
    ├── 01KH0CDM4N96NQKV4XGWD5K06T/
    ├── 01KHNV28WRAZCB7JQ0ZVAET074/
    ├── 01KHRDEZYGQ6XAAC3H3BEHFCHH/
    ├── 01KHXBCPS5KWC5RBTW3NJ22A5Q/
    ├── 01KHZ967Z3RJQV2730FWEAEP0M/
    ├── 01KJ16XYN63TJ1P9WTKYHHS9BJ/
    ├── 01KJ1MNCZS60R060Y34WSGEZ3N/
    ├── 01KJ1VH47S8CB2B37N78813G4T/
    ├── 01KJ1VH49NGQJWNYT2QCKYQPJH/
    ├── 01KJ22CVFYR0ANCM9F2E7KJJQ5/
    ├── chunks_head/
    ├── lost+found
    ├── queries.active
    └── wal/
```

Data was migrated with the following commands:

```sh
cp /mnt/old/01* /mnt/new/prometheus-db

rm -rf /mnt/new/prometheus-db/wal/* /mnt/new/prometheus-db/chunks_head/*
cp -ra /mnt/old/wal/* /mnt/new/prometheus-db/wal/
cp -ra /mnt/old/chunks_head/* /mnt/new/prometheus-db/chunks_head/
```

While the owner permission did not match, the group permission matched and there were no issues.

## Resource Usage Monitoring

Knowing how much resources a particular application uses is necessary for troubleshooting resource shortage and evaluating competing apps.

Intuitively, it would be sufficient to aggregate resource usage of all pods and group by the application label.  
However in practice, this is not so simple.

All applications deployed via Argo CD are annotated with a tracking ID ([ref](https://argo-cd.readthedocs.io/en/stable/user-guide/resource_tracking/)) so it should be possible to group by this ID
- Argo CD only annotates top-level manifests with the application name
- Helm charts don't always propagate the annotation down to the pods
  - Helm appears to use the `app.kubernetes.io/instance` label instead
  - Helm sets the label value to the chart release name
    - Helm chart managed by Kustomize sets release name = `release-name` by default

Kube-prometheus-stack automatically configures Kube-state-metric to aggregate resource usage to its top-level manifest entity but this is not enough because complex helm charts with sub-charts show up as distinct entities
- Uses `app.kubernetes.io/instance` label

Another solution is to sum up pod resource usage by namespace under the following assumptions:
- Applications map 1:1 to a namespace
  - An application deploys all pods to the same namespace
  - No two applications deploy pods to the same namespace

However, some applications deploy pods to multiple namespaces
- Istio deploys CNI and Ztunnel in a privileged namespace (`kube-system`)
- Prometheus node exporter is deployed in a privileged namespace (`kube-system`)

### Aggregating Metrics

Most applications deploy to a single namespace. The exceptions are for components that require greater privileges.
- Node level deployments (daemonsets)
- Infrastructure components
  - Routing components
  - Node monitoring components

Since the exceptions are rare, the simplest solution is to integrate the extra pods on an individual basis.  
This requires a mapping for pods in the privileged namespace to the parent application.  
- `app.kubernetes.io/instance` label
  - Kustomize assigns ambiguous release name to Helm charts as mentioned above
- `app.kubernetes.io/name` label
  - A single application may deploy several prileged components with distinct names
    - Should still work, but require more integration effort
- `app.kubernetes.io/part-of` label
  - Similar to `app.kubernetes.io/name` label but is a higher grouping level
    - Expected to have equal or less entries compared to `app.kubernetes.io/name`

Integrating the exceptions can be done in a few ways:
- Define a prometheus rule for a new metric that aggregates the resource usage
  - Exception handling is built into a complex query
  - Exception handling logic is duplicated for each resource type
  - Data manipulation logic is put into a DB
- Define a prometheus rule for tagging pods with the corresponding application name
  - For pods in a namespace managed by an Argo CD app: target pods using namespace and apply Argo CD app name
  - For pods in `kube-system` managed by an Argo CD app: target pods using label filter and apply Argo CD app name

Assuming no Argo CD app takes control of `kube-system` namespace, the same tag can be used for base case and edge case.

### Better Observability Resolution for Kube-Prometheus-Stack

Kube-prometheus-stack deploys 3 types of containers
- Prometheus node exporter
- Kube-state-metrics
- Prometheus

Naively deploying the bundled Helm chart and aggregating the data as explained above results in all 3 types of containers being merged into a single data group. This can be problematic when comparing against other prometheus-compatible alternatives
- [VictoriaMetrics](https://victoriametrics.com/products/open-source/)
- [Grafana Mimir](https://grafana.com/oss/mimir/)

By deploying the node exporter and kube-state-metrics to another namespace, it is possible to isolate the resource usage attributed to the prometheus operator
