resource "proxmox_virtual_environment_download_file" "archlinux_img" {
	content_type = "vztmpl"
	datastore_id = var.host_storage_management
	node_name = var.host_node_name
	url = var.devlab.template_url
}

module "devlab" {
	source = "./modules/lxc"

	node_name = var.host_node_name
	name = var.devlab.name
	vm_id = var.devlab.vm_id
	password = var.devlab.password
	description = var.devlab.description

	privileged = false
	cpu_cores = var.devlab.cpu_cores
	ram = var.devlab.ram
	bridge_network = local.network.name
	interface_name = "devlab"
	mac_address = var.devlab.mac_address

	datastore_id = var.host_storage_vdisk
	disk_size = var.devlab.disk_size
	template_file_id = proxmox_virtual_environment_download_file.archlinux_img.id
	distro = "archlinux"
}
