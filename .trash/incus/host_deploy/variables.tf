variable "nics" {
	description = "List of {MAC address, IPv4 address} mappings"
	type = list(object({
		name = string
		mac = string
		ip4 = string
	}))
}

variable "nic_host" {
	description = "Index of `var.nics` used by the hypervisor host"
	type = number

	validation {
		condition = 0 <= var.nic_host && var.nic_host < length(var.nics)
		error_message = "The nic_host value must be a valid index of nics list"
	}
}

variable "nic_fw" {
	description = "Indices of `var.nics` passed into the firewall / router"
	type = list(number)

	validation {
		condition = alltrue([for i in var.nic_fw :
			0 <= i && i < length(var.nics)
			&& i != var.nic_host
		])
		error_message = "The nic_host value must be a valid index of nics list"
	}
}
