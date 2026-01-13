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

## Troubleshooting

### Templating VM resources

All VMs share certain common attributes (CPU type, storage, etc) but some VMs may require attributes not used by others.  
OpenTofu has limited support for pre-defining common attributes while retaining full access to the original resource API.

After searching for solutions and considering the options below, I chose to use OpenTofu modules.  
Parts of the API I will not require immediately has been left out from the module.  
Not sustainable if requirements become more complex, but it is the appropriate level of abstraction for current scale.

#### For-each + Dynamic block

The template must re-declare every API of the resource in order to allow adding new top level attributes.  
This becomes awkward for top-level blocks and resources with complex API.  
This also merges all usage into a single definition, masking relationship between resource instances.

#### Modules

This has almost the same benefits and drawbacks as `For-each + Dynamic block` approach.  
It however allows logically unrelated resource instances to be defined separately

#### JSON Generation

OpenTofu accepts JSON as alternative format.

Define template and concrete instance in an alternative configuration language.
- YAML + Merge with `yq`
- Pkl (native support for inheritance) + JSON export

Fragile and Lose HCL expressiveness.  
Does not integrate well with OpenTofu.

#### Terramate Code Generation

Orchestration tool designed for code generation.  
Deemed excessive at current scale.
