locals {
	# Proxmox node address as IP / FQDN
	host_ssh_address = var.host_fqdn != "" ? var.host_fqdn : var.host_ip4.address

	# Network switch alias
	network = proxmox_virtual_environment_network_linux_bridge.switch

	# Talos bootstrapping
	talos_cluster_name = "cluster"
	talos_master_address = module.kubemaster[0].ipv4[1][0]
	talos_cluster_endpoint = "https://${local.talos_master_address}:6443"
}
