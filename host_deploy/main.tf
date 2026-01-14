terraform {
	required_version = ">= 1.11.0"

	backend "local" {
		# Prevent backup files cluttering the directory
		path = "state/terraform.tfstate"
	}

	required_providers {
		proxmox = {
			source = "bpg/proxmox"
			version = "0.93.0"
		}

		talos = {
			source = "siderolabs/talos"
			version = "0.10.0"
		}
	}
}

provider "proxmox" {
	endpoint = var.host_web_address
	insecure = !var.host_web_tls
	# --- BEGIN Authentication ---
	username = var.host_web_username
	password = var.host_web_password
	# --- END Authentication ---

	ssh {
		node {
			name = var.host_node_name
			address = local.host_ssh_address
			port = var.host_ssh_port
		}
	}

}

provider "talos" {}
