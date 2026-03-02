# Metrics Unit

## CPU Usage

- `container_cpu_usage_seconds_total`: Cummulative CPU time (second)
- `rate([$__rate_interval])`: CPU core utilization during `$__rate_interval` (decimal)
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

## Node statistics

- `node_cpu_seconds_total{mode!="steal"}`: Sum CPU time available to each node
    - Exclude `mode == steal` for VM nodes to exclude hypervisor overhead
    - Get list of all modes via `count by (mode) (node_cpu_seconds_total)`

3 panels were created for visualizing node resource utilization
- CPU time of nodes and applications
- Memory of nodes and applications
- Utilization percentage of CPU and Memory

To prevent duplicate queries to prometheus, a panel can reuse queries from another panel in the same dashboard. The utilization panel can calculate the ratio of values in the previous two panels.

However, the series names are not unique across panels so when the query results are pulled into the utilization panel, the names overlap. For queries pulled in from another dashboard, their names cannot be aliased in the query tab and thus cannot be referenced in the `Transformations` tab properly.

### Hacky solution

`Prepare time series` transformation in `Multi-frame time series` forcibly adds the `name: undefined` attribute to the pulled in data.

This allows `Join by field` to assign a default name of `Value #` where `#` is auto-incremented.

After the utilization metrics are computed, the source data can be hidden and the computed data renamed with `Organize fields by name`
