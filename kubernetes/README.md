# Kubernetes Deployment

Applications deployed using [Argo CD](https://argo-cd.readthedocs.io/en/stable/)
- Standard installation
- Not high availability
	- Start simple

## Directory Structure

```
./
├── bootstrap  <─────────────────┐
│   └── *.yaml                   │
└── apps                         │
    ├── root  <─────────┐        │
    │   ├── root.yaml ──┘        │
    │   ├── argo-cd.yaml ──┐     │
    │   └── <others>.yaml ━┿━━┓  │
    ├── argo-cd  <─────────┘  ┃  │
    │   └── *.yaml ───────────╂──┘
    └── <others>  <━━━━━━━━━━━┛
        └── *.yaml
```

App (`./apps/root/`) of Apps (`./apps/*`) Pattern

- Root app manages every app, including Argo CD and Root app itself
- Argo CD definition is split across `./apps` and `./bootstrap`
	- `./bootstrap` contains the bare minimum to install
	- `./apps/argo-cd` contains additional configs

## Bootstrap

Assumption: A fresh kubernetes cluster provisioned by [OpenTofu IaC](../host_deploy)

0. Obtain cluster kubeconfig via `tofu output -raw kubeconfig`
	> Save to `~/.kube/config`  
	> Or `export KUBECONFIG=<path>`  
	> Or `kubectl --kubeconfig=<path>`
1. Install Argo CD via `kubectl apply --server-side -k ./bootstrap`
	> Failing to add `--server-side` results in an error:  
	> `The CustomResourceDefinition "applicationsets.argoproj.io" is invalid: metadata.annotations: Too long: may not be more than 262144 bytes`  
	> [Known issue](https://argo-cd.readthedocs.io/en/latest/operator-manual/upgrading/3.2-3.3/#applicationset-crd-exceeds-the-size-limit-for-client-side-apply)
2. Instantiate Root app via `kubectl apply -f ./apps/root/root.yaml`
	> Acquire initial Argo CD web UI password: `kubectl get secrets -n argocd argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d`  
	> Access Argo CD web UI: `kubectl port-forward svc/argocd-server -n argocd 8080:443`
3. Update Argo CD user via `./bootstrap/setpw.sh <username> '<bcrypt hash>'`
	> Assumes `<username>` role is login only

## Deploying a new application

- Create a directory under `./apps` with the application name
- Define application under its directory
- Register application under `./apps/root`

## Networking

### Goals

- Every service should be reachable with a constant entry point
	- Either IP / Subdomain + Path
- Each service should be independently configurable
	- Ideally, configuring one service should not require knowledge of how other services are configured
	- Address assignment should be automatic without conflict

### Strategy

- L4 services
	- IP address allocated by load balancer
		- Use [MetalLB](https://metallb.io/)
	- DNS records for services updated to point to its allocated IP address
		- Use [ExternalDNS](https://kubernetes-sigs.github.io/external-dns/latest/) to issue DNS record updates
		- Deploy a DNS server as a service
			- [Pi-hole](https://pi-hole.net/)
				- Wildcard domains not supported OOTB
			- [Adguard Home](https://adguard.com/en/adguard-home/overview.html)
			- [Technitium](https://technitium.com/)
	- For shared resources
		- eg: Persistence
- L7 services
	- Subdomain / Path based routing
		- [Kubernetes Gateway API](https://kubernetes.io/docs/concepts/services-networking/gateway/)
- Future plans
	- Consider [Cilium](https://cilium.io/)
		- Can handle L4 + L7 load balancing
