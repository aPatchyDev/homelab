# https://docs.siderolabs.com/talos/v1.12/platform-specific-installations/virtualized-platforms/proxmox
# Ballooning is not recommended
# VirtIO SCSI Single may cause issues
resource "proxmox_virtual_environment_download_file" "talos_iso" {
	content_type = "iso"
	datastore_id = var.host_storage_management
	node_name = var.host_node_name
	url = "https://factory.talos.dev/image/${var.talos_iso.schematic_id}/${var.talos_iso.version}/metal-amd64.iso"
	file_name = "talos-${var.talos_iso.version}.iso"
}

module "kubemaster" {
	source = "./modules/vm"
	count = var.talos_master.count

	name = "${var.talos_master.name}-${count.index + 1}"
	vm_id = var.talos_master.first_id + count.index
	description = "[#${count.index + 1}] ${var.talos_master.description}"
	node_name = var.host_node_name

	cpu_cores = var.talos_master.cpu_cores
	ram = var.talos_master.ram
	ballooning = false
	qemu_agent = true
	bridge_network = local.network.name
	mac_address = var.talos_master.mac_addresses[count.index]

	scsi_hardware = "virtio-scsi-pci"
	datastore_id = var.host_storage_vdisk
	disk_size = var.talos_master.disk_size
	installer_file_id = proxmox_virtual_environment_download_file.talos_iso.id
}

module "kubeworker" {
	source = "./modules/vm"
	count = var.talos_worker.count

	name = "${var.talos_worker.name}-${count.index + 1}"
	vm_id = var.talos_worker.first_id + count.index
	description = "[#${count.index + 1}] ${var.talos_worker.description}"
	node_name = var.host_node_name

	cpu_cores = var.talos_worker.cpu_cores
	ram = var.talos_worker.ram
	ballooning = false
	qemu_agent = true
	bridge_network = local.network.name
	mac_address = var.talos_worker.mac_addresses[count.index]

	scsi_hardware = "virtio-scsi-pci"
	datastore_id = var.host_storage_vdisk
	disk_size = var.talos_worker.disk_size
	installer_file_id = proxmox_virtual_environment_download_file.talos_iso.id
}
