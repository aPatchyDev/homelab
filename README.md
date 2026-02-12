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

## .trash/

Archive for abandoned tech stack

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

### Kubernetes

Deploying secrets to kubernetes services require additional integration effort.

#### SOPS

Since this repository already uses SOPS, this was the first choice.

- [KSOPS](https://github.com/viaduct-ai/kustomize-sops)
	- Invasively patch Argo CD service
	- Secrets are managed by Argo CD [which is not recommended](https://argo-cd.readthedocs.io/en/stable/operator-manual/secret-management/)
- [isindir SOPS operator](https://github.com/isindir/sops-secrets-operator)
	- Secrets are managed by Argo CD [which is not recommended](https://argo-cd.readthedocs.io/en/stable/operator-manual/secret-management/)
	- Poor documentation
	- Require only data fields to be encrypted
- [peak-scale SOPS operator](https://github.com/peak-scale/sops-operator)
	- Poor documentation
	- Require only data fields to be encrypted

Since none of the options integrate well with the existing setup, there was no reason to require SOPS.

#### Self hosted secret manager

Requires stateful storage, which requires connection credentials, creating a circular dependency

#### Cloud based secret manager

To retrieve secrets outside the git repository, I chose to use [external-secrets](https://external-secrets.io/latest/).

- [Hashicorp Vault](https://www.hashicorp.com/en/products/vault)
	- Company has history of rug-pulling
- [Google Cloud Secret Manager](https://cloud.google.com/security/products/secret-manager)
	- Free tier allows very small number of secrets
	- Uncertain when [Always Free](https://docs.cloud.google.com/free/docs/free-cloud-features#secret-manager) policy will change
- [Gitlab CI/CD variables](https://docs.gitlab.com/api/project_level_variables/)
	- Not originally designed to be a secret manager

---

If I am going to use an external provider, it would be easier to manage if everything uses the same provider.  
Hence [Gitlab](https://gitlab.com/aPatchyDev/homelab-secrets) was chosen.
- Terraform state
- Kubernetes secrets
