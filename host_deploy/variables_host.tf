# Proxmox node
variable "host_node_name" {
	description = "Proxmox node name"
	type = string
}

variable "host_ip4" {
	description = "Proxmox node IPv4 address"
	type = object({
		address = string
		cidr = number
	})
}

variable "host_fqdn" {
	description = "Proxmox node fully qualified domain name"
	type = string
	default = ""
}

# Proxmox web
variable "host_web_address" {
	description = "Proxmox web URI"
	type = string
	ephemeral = true
}

variable "host_web_tls" {
	description = "Host web TLS verification"
	type = bool
	ephemeral = true
}

variable "host_web_username" {
	description = "Proxmox web username"
	type = string
	ephemeral = true
}

variable "host_web_password" {
	description = "Proxmox web password"
	type = string
	sensitive = true
	ephemeral = true
}

# Proxmox ssh
variable "host_ssh_port" {
	description = "Proxmox ssh port"
	type = number
	ephemeral = true
	default = 22
}

# Proxmox storage
variable "host_storage_vdisk" {
	description = "Proxmox storage for VM / LXC virtual disk"
	type = string
}

variable "host_storage_management" {
	description = "Proxmox storage for ISO / Backup / Template"
	type = string
}
