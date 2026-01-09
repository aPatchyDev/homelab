# Make the host a network switch
resource "proxmox_virtual_environment_network_linux_bridge" "switch" {
	node_name = var.host_node_name
	name = "vmbr0"
	comment = "Network switch"
	autostart = true

	# Assign host address to the bridge
	# Assign physical ports as bridge ports
	address = "${var.host_ip4.address}/${var.host_ip4.cidr}"
	ports = ["eth0", "eth1", "eth2", "eth3", "eth4", "eth5"]

	lifecycle {
		ignore_changes = [
			# Don't control gateway address - leave it to uplink DHCP
			gateway
		]
	}
}
