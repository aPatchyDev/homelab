terraform {
	required_version = ">= 1.11.0"

	required_providers {
		proxmox = {
			source = "bpg/proxmox"
			version = "0.91.0"
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
