variable "node_name" {
	type = string
}

variable "name" {
	description = "Valid DNS hostname as VM name (Proxmox restriction)"
	type = string
}

variable "vm_id" {
	type = number
}

variable "description" {
	type = string
}

variable "autostart" {
	type = bool
	default = true
}

variable "cpu_cores" {
	type = number
}

variable "ram" {
	description = "RAM in MiB"
	type = number
}

variable "ballooning" {
	type = bool
}

variable "qemu_agent" {
	type = bool
}

variable "bridge_network" {
	type = string
}

variable "mac_address" {
	type = string
}

variable "scsi_hardware" {
	type = string
	default = "virtio-scsi-single"
}

variable "datastore_id" {
	type = string
}

variable "disk_size" {
	description = "Disk size in GiB"
	type = number
}

variable "installer_file_id" {
	type = string
	default = "none"
}
