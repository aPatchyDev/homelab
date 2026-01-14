output "vm" {
	description = "The full virtual machine instance"
	value = proxmox_virtual_environment_vm.this
}

output "ipv4" {
	description = "List of IPv4 addresses"
	value = [for it in proxmox_virtual_environment_vm.this.ipv4_addresses : it if length(it) > 0]
}

resource "proxmox_virtual_environment_vm" "this" {
	node_name = var.node_name

	# VM details
	name = var.name
	vm_id = var.vm_id
	description = var.description
	on_boot = var.autostart

	cpu {
		type = "host"
		cores = var.cpu_cores
	}

	memory {
		dedicated = var.ram
		floating = var.ballooning ? var.ram : 0
	}

	agent {
		enabled = var.qemu_agent
		wait_for_ip {
			ipv4 = true
		}
	}

	# Network
	network_device {
		bridge = var.bridge_network
		mac_address = var.mac_address
	}

	# Main virtual disk
	scsi_hardware = var.scsi_hardware
	disk {
		interface = "scsi0"
		datastore_id = var.datastore_id
		cache = "writeback"
		aio = "io_uring"
		# IPv4 addresses are not populated if set incorrectly
		# https://github.com/bpg/terraform-provider-proxmox/issues/776#issuecomment-1848801583
		iothread = var.scsi_hardware == "virtio-scsi-single"
		ssd = true
		discard = "on"
		file_format = "raw"
		size = var.disk_size
	}

	# Installer ISO
	cdrom {
		interface = "ide3"
		file_id = var.installer_file_id
	}

	# Boot to main virtual disk otherwise installer
	boot_order = ["scsi0", "ide3"]
}
