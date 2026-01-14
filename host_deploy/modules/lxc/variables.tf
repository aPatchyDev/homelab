variable "node_name" {
	type = string
}

variable "name" {
	type = string
	description = "Valid DNS hostname"
}

variable "vm_id" {
	type = number
}

variable "description" {
	type = string
}

variable "privileged" {
	type = bool
}

variable "password" {
	type = string
	sensitive = true
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

variable "bridge_network" {
	type = string
}

variable "interface_name" {
	type = string
}

variable "mac_address" {
	type = string
}

variable "datastore_id" {
	type = string
}

variable "disk_size" {
	description = "Disk size in GiB"
	type = number
}

variable "template_file_id" {
	type = string
}

variable "distro" {
	description = "Make Proxmox execute OS specific setup in /usr/share/lxc/config"
	type = string
}
