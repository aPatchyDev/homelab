# Homelab Configuration

Repository for managing a homelab

Additional info for each component resides in its `**/README.md` file

## Intialization

This repository uses git clean / smudge filters to manage secrets encrypted with SOPS + age.

Configure the environment to supply age key file before running `setup.sh`
- `export SOPS_AGE_KEY_FILE=<path>`
- `$XDG_CONFIG_HOME/sops/age/keys.txt`

## Goals

- Repeatable setup
	- Restoration after full disk wipe should be straightforward
- Single source of truth
	- This repo should define the state of the system via CI/CD
- Experiment with new tech
	- Virtualization
	- Infrastructure as Code
	- Kubernetes
	- Monitoring
	- Cool / Useful self-hosted tools
	- and more

## Non-Goals

- High availability
	- No plans for operating critical systems
	- No spare hardware at hand
	- May be powered off at times to save power
- Public service
	- Primarily host services for LAN

## Secrets

Homelab IaC will require storing secrets in some form.  
Using external services require provisioning infrastructure (chicken and egg problem) and may not be free.

Candidates
- Secondary private repository
	- Also support terraform state via [custom backend](https://github.com/plumber-cd/terraform-backend-git)
- Gitlab
	- [Generic secret files](https://docs.gitlab.com/ci/secure_files/)
		- Max 5 MB files
	- [Terraform state](https://docs.gitlab.com/user/infrastructure/iac/terraform_state/)
- Encrypted secrets
	- Self contained repository
	- No vendor lock in
	- Good [git integration](https://github.com/aPatchyDev/git-sops)
	- Poor key rotation support
		- Rotating key does not invalidate previous file versions
		- Require rewriting history to hide old secret files

Choice: Encrypted secrets with SOPS
- Self contained homelab repo
- Try something new
	- Only possible because this homelab is intended for internal LAN only
	- Gitlab appears to be the most sensible choice for future personal projects
