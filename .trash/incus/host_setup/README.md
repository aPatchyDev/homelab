# Bare metal host setup

## Device Info

- Intel N100 MiniPC
- 16GiB DDR5 4800MHz RAM
- 6 Intel i226-V NIC

## Static IP Assignment

- Reserved DHCP IP for each Ethernet port
- Must be configured before setting up this host

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

Choice: Incus OS
- IaC support
- Try something new

## IncusOS Installation

[Seed Reference](https://linuxcontainers.org/incus-os/docs/main/reference/seed/)
- force_install: Wipe disk on install
- preseed.security.missing_tpm: Disable TPM requirement
	- Install will halt if seed does not explicitly allow swtpm
- [apply_defaults](https://linuxcontainers.org/incus-os/docs/main/reference/applications/incus/)
	- Create default storage pool
	- Create local network bridge
	- Set trusted client certificates
	- Listen on port 8443

Cannot use Web image downloader
- extra json fields in request body are silently dropped

Incompatible with ventoy
- [Reference](https://discuss.linuxcontainers.org/t/incusos-first-impressions-on-a-laptop/25153/2)

## Installation Process

1. Enable Secure Boot
	- Set BIOS password to allow setting modification
		- BIOS PW = `admin`
	- Enable Secure Boot
		- Save and Reboot
	- Reset to Setup Mode
2. Install IncusOS
3. Add Factory Keys
	- Append `Key Exchange Keys (KEK)`
	- Append `Authorized Signatures (db)`
