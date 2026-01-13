output "vm" {
	description = "The full virtual machine instance"
	value = proxmox_virtual_environment_vm.this
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
		iothread = true
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
