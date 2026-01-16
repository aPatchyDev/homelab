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

## Deploying a new application

- Create a directory under `./apps` with the application name
- Define application under its directory
- Register application under `./apps/root`
