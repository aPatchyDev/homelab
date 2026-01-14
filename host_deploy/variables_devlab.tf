variable "devlab" {
	type = object({
		template_url = string
		# Must be a valid DNS hostname
		name = string
		vm_id = number
		description = string
		password = string
		cpu_cores = number
		# RAM in MiB
		ram = number
		mac_address = string
		# Disk size in GiB
		disk_size = number
	})
}
