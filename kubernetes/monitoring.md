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
