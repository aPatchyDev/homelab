# Monitoring

Prometheus was chosen as it seems to be the de-facto standard for monitoring.

## Storage Monitoring

As mentioned in [../host_setup/README.md](../host_setup/README.md), I wanted to monitor ZFS ARC cache hit rate.

Proxmox can push metrics to an external server, although [documentation on what data is included is lacking](pve.proxmox.com/wiki/External_Metric_Server).  
Based on some existing Grafana dashboards ([1](https://grafana.com/grafana/dashboards/13307-proxmox-ve/), [2](https://grafana.com/grafana/dashboards/10048-proxmox/), [3](https://grafana.com/grafana/dashboards/24550-proxmox-ve-pve-exporter/)) the metrics for ZFS does not seem to include what I wanted to track:
- ZFS cache hit rate
- Disk S.M.A.R.T. status

Since I intend to use Prometheus for monitoring other workloads, I opted to using prometheus exporters.  
ZFS metrics can be obtained from the host system via [Node Exporter](https://prometheus.io/docs/guides/node-exporter/) which is available as a [debian package](https://github.com/prometheus-community/smartctl_exporter).  
Disk S.M.A.R.T metrics can be obtained from the host system via [Smartctl Exporter](https://github.com/prometheus-community/smartctl_exporter) although this is [only packaged for Debian Sid](https://pkgs.org/download/prometheus-smartctl-exporter) and would require installation outside the system package manager as of now.
