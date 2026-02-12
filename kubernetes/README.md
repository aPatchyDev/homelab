# Kubernetes Deployment

Applications deployed using [Argo CD](https://argo-cd.readthedocs.io/en/stable/)
- Standard installation
- Not high availability
	- Start simple

## Directory Structure

```
./
├── bootstrap  <─────────────────┐
│   └── *.yaml                   │
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

	> Acquire initial Argo CD web UI password: `kubectl get secrets -n argocd argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d`  
	> Access Argo CD web UI: `kubectl port-forward svc/argocd-server -n argocd 8080:443`
2. Register Gitlab access token via `./bootstrap/setgitlab.sh '<access token>'`
	> Require `Maintainer` role + `read_api` scope  
	> [Reference](https://docs.gitlab.com/user/permissions/#project-cicd)
3. Instantiate Root app via `kubectl apply -f ./apps/root/root.yaml`
	> Ensure Argo CD credentials are set in Gitlab

## Deploying a new application

- Create a directory under `./apps` with the application name
- Define application under its directory
- Register application under `./apps/root`

## Rationales

### Networking

Refer to [networking.md](./networking.md) for detail.

### Storage

Configuring networking to work with domain names require a DNS server with stateful persistent storage to store the mappings.

Since the DNS server is deployed via kubernetes, it should be deployable to any of the worker nodes, in which case, using local storage of each kubernetes node (VM) is not desirable.
- Couples the service with a particular node
- Or introduce hurdles when migrating to another node

Thus arises the need for network storage decoupled from any individual node
- Remote storage server
- Or storage cluster

Refer to [storage.md](./storage.md) for detail.

### Secrets

Choosing a remote storage backend that lives outside kubernetes creates a dependency on managing connection credentials as secrets.

Refer to [../README.md#secrets](../README.md#secrets) for detail.

### Monitoring

Refer to [monitoring.md](./monitoring.md)
