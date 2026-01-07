terraform {
	required_version = ">= 1.11.0"

	required_providers {
		incus = {
			source = "lxc/incus"
			version = "1.0.2"
		}
	}
}

provider "incus" {
	accept_remote_certificate = true
	default_remote = "homelab"

	remote {
		name = "homelab"
		address = var.nics[var.nic_host].ip4
	}
}

# IncusOS automatically creates a default pool "local"
# https://linuxcontainers.org/incus-os/docs/main/tutorials/storage-expand-local-pool/
data "incus_storage_pool" "default" {
	name = "local"
}
