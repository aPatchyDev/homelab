variable "gitlab_project_id" {
	type = string
}

variable "gitlab_state_name" {
	type = string
}

variable "tfstate_passphrase" {
	type = string
	sensitive = true
	ephemeral = true
}
