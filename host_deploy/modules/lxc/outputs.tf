output "lxc" {
	description = "The full LXC container instance"
	value = proxmox_virtual_environment_container.this
}

resource "proxmox_virtual_environment_container" "this" {
	node_name = var.node_name

	# LXC details
	vm_id = var.vm_id
	description = var.description
	start_on_boot = var.autostart
	unprivileged = !var.privileged

	initialization {
		hostname = var.name

		ip_config {
			ipv4 {
				address = "dhcp"
			}
		}

		user_account {
			password = var.password
		}
	}

	cpu {
		cores = var.cpu_cores
	}

	memory {
		dedicated = var.ram
	}

	network_interface {
		bridge = var.bridge_network
		mac_address = var.mac_address
		name = var.interface_name
	}

	wait_for_ip {
		ipv4 = true
	}

	disk {
		datastore_id = var.datastore_id
		size = var.disk_size
		mount_options = []
	}

	operating_system {
		template_file_id = var.template_file_id
		type = var.distro
	}

	features {
		nesting = true
		fuse = true
		mount = []
	}

	lifecycle {
		ignore_changes = [
			environment_variables,
			tags
		]
	}
}
