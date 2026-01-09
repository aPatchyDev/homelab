# OpenTofu IaC

IaC to provision virtualization resources using [Proxmox provider](https://search.opentofu.org/provider/bpg/proxmox/latest)
- `bpg/proxmox`

## Goals

- Configure networking
	- Network switch
	- Virtual interfaces
- Create ZFS storage volume
- Create LXC / VM
- Configure Monitoring

### Desired outcome

- Host network switch
- 4 Kubernetes node
	- 2 Control plane node
	- 2 Worker node
- 1 Dev node
	- Long running task
	- Temporary services

### Future goals

- Harden security
	- Limit SSH to local network
		- `bpg/proxmox` terraform provider relies on SSH for parts of its operation
		- Look into key based authentication
- QoL improvements
	- Power optimization
	- Memory compression
	- WoL

## Storage

Physical node only has 1 SSD formatted with ZFS.  
To avoid write amplification from nested file system, use Zvol (raw block device) for virtual disk.

## Nodes

### Kubernetes

Running kubernetes directly on the host or LXC container has its own challenges.  
Following popular recommendations, a VM is used to run kubernetes nodes.

Talos OS was chosen to minimize management fatigue
- Immutable + Purpose-built
- Offers [image factor](https://factory.talos.dev/)

### Dev

This node will be used for running miscellaneous tasks I do not want to run on my main PC.  
Considering the weak compute power of the host system, I will not be running compute-intensive work.  
Therefore a LXC container is used to run a dev environments.
