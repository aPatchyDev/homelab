# Bare metal host setup

## Device Info

- Intel N100 MiniPC
- 16GiB DDR5 4800MHz RAM
- 512GiB NVMe SSD
- 6 Intel i226-V NIC

## Static IP Assignment

- Reserved DHCP IP for each Ethernet port
	- Only to prevent the address being assigned to another client

## Hypervisor Choice

Requirements
- Free
- Open Source
	- Prevent future license change / lock-down
- Lightweight
- Simple
	- No remote host management expected
	- No VM migration expected

Candidates
- [Proxmox](https://www.proxmox.com/)
	- Have used before
	- Based on debian
	- IaC only by 3rd party
- [Incus OS](https://linuxcontainers.org/incus-os/)
	- Immutable OS
		- Based on debian minimal
	- Official IaC support

Choice: Proxmox
- Tried and abandoned IncusOS
	- Limited host network configuration
	- Poor documentation

## Proxmox Planning

[Reference](https://github.com/SwamiRama/10-ways-to-ruin-proxmox/)

- RAM
	- ZFS: 3~4 GiB
	- Host: 2 GiB
	- Target ~10 GiB total for virtualization workloads
- File System
	- ZFS
		- Mostly for compression
	- `c_min`: 3 GiB
		- Base: 2 GiB
		- Storage: 0.5 TiB * 1 GiB / TiB = 0.5 GiB
		- Round up for safety margin
	- `c_max`: 4GiB
		- File caching: 1 GiB
		- Subject to change based on real usage
			- Monitor ZFS metric
			- Target 80% hit rate
	- `compress`: LZ4
		- LZ4 runs faster
		- ZSTD compresses better
		- Prioritize CPU overhead
