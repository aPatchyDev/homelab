variable "talos_iso" {
	type = object({
		schematic_id = string

		# v0.0.0
		version = string
	})
}

variable "talos_master" {
	type = object({
		# Number of master nodes
		count = number

		# Each node is assigned an integer ID in [first_id, first_id + count)
		first_id = number

		# List of MAC addresses for each node
		# Configure uplink router to assign IP based on MAC address
		mac_addresses = list(string)

		# Each node name is suffixed by 1-indexed number
		# Must be a valid DNS hostname (Proxmox restriction)
		name = string

		# Each node description is prefixed by 1-indexed number
		description = string

		cpu_cores = number

		# RAM in MiB
		ram = number

		# Disk size in GiB
		disk_size = number
	})
}

variable "talos_worker" {
	type = object({
		# Number of worker nodes
		count = number

		# Each node is assigned an integer ID in [first_id, first_id + count)
		first_id = number

		# List of MAC addresses for each node
		# Configure uplink router to assign IP based on MAC address
		mac_addresses = list(string)

		# Each node name is suffixed by 1-indexed number
		# Must be a valid DNS hostname (Proxmox restriction)
		name = string

		# Each node description is prefixed by 1-indexed number
		description = string

		cpu_cores = number

		# RAM in MiB
		ram = number

		# Disk size in GiB
		disk_size = number
	})
}
