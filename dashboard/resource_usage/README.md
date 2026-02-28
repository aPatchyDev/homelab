# Metrics Unit

## CPU Usage

- `container_cpu_usage_seconds_total`: Cummulative CPU time (second)
- `rate([1m])`: CPU core utilization during `1m` (decimal)
    - Multiplied by `1000`: milli-core (mCPU)
        - `1000` = Total utilization of 1 CPU core

### Why mCPU?

CPU usage can be represented in several ways:
- Utilization of total CPU capacity
    - Clearly shows system's leeway
    - Difficult to compare usage among applications
- Utilization of 1 CPU core
    - Directly comparable among applications
        - Normalization required for clusters with varying CPU capabilities
    - Difficult to see system's leeway

The motivation for collecting this metric was to optimize resource usage, either by scaling down quota or switching to an alternative application. Thus, direct comparison was more important.

## Memory Usage

- `container_memory_working_set_bytes`: Currently used memory (byte)

## Disk IO

- `container_fs_reads_bytes_total`: Cummulative disk read (byte)
    - `container_fs_writes_bytes_total`: Cummulative disk write (byte)
- `increase([$__rate_interval])`: Disk read/write during `$__rate_interval` (byte)

### Why not throughput?

Most applications use the disk sparsely, so throughput is not very interesting outside of media streaming services. Both throughput and data transferred offer similar insight on usage spikes, but data transferred offers more insights when the interval widens.

## Network IO

- `container_network_receive_bytes_total`: Cummulative ingress (byte)
    - `container_network_transmit_bytes_total`: Cummulative egress (byte)
- `increase([$__rate_interval])`: Network read/write during `$__rate_interval` (byte)

### Why not throughput?

The cluster is expected to operate without sustained network traffic, so throughput is not very interesting.
