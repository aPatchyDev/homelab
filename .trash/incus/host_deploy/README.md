# OpenTofu IaC

IaC to provision virtualization resources using [Incus provider](https://search.opentofu.org/provider/lxc/incus/latest)

## OPNsense

OPNsense does not provide a pre-built VM image and  
OpenTofu is not great for creating a VM with OS installer

OPNsense is built on FreeBSD and  
there is a [tool](https://github.com/maurice-w/opnsense-vm-images/tree/master?tab=readme-ov-file) to bootstrap OPNsense

## Talos OS

Running kubernetes directly on the host or LXC container has its own challenges.  
Following popular recommendations, a VM is used to house kubernetes nodes.  

Talos OS provides an [image factor](https://factory.talos.dev/) with [api docs](https://github.com/siderolabs/image-factory/blob/main/docs/api.md)
