terraform {
	required_version = ">= 1.11.0"

	backend "http" {
		address = local.backend_address
		lock_address = "${local.backend_address}/lock"
		unlock_address = "${local.backend_address}/lock"
		lock_method = "POST"
		unlock_method = "DELETE"
		retry_wait_min = 5
		# Define the credentials in secret_config.http.tfbackend
		# username = "<username>"
		# password = "<Maintainer | Owner + api scoped token>"
	}

	encryption {
		key_provider "pbkdf2" "by_passphrase" {
			passphrase = var.tfstate_passphrase
		}

		method "aes_gcm" "encrypt" {
			keys = key_provider.pbkdf2.by_passphrase
		}

		state {
			method = method.aes_gcm.encrypt
			enforced = true
		}
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
