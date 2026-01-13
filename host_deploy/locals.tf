locals {
	# Proxmox node address as IP / FQDN
	host_ssh_address = var.host_fqdn != "" ? var.host_fqdn : var.host_ip4.address

	# Network switch alias
	network = proxmox_virtual_environment_network_linux_bridge.switch
}
