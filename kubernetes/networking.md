# Networking

## Goals

- Every service should be reachable with a constant entry point
	- Either IP / Subdomain + Path
- Each service should be independently configurable
	- Ideally, configuring one service should not require knowledge of how other services are configured
	- Address assignment should be automatic without conflict

## Strategy

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

## Current status

- Components
    - IP allocation: [MetalLB](https://metallb.io/)
    - Gateway API: [Istio](https://istio.io/)
    - DNS: [Adguard Home](https://adguard.com/en/adguard-home/overview.html) + [ExternalDNS](https://kubernetes-sigs.github.io/external-dns/latest/)
- Static IP allocation via `metallb.io/loadBalancerIPs` annotation
	- For network infrastructure only
		- DNS server backed by Adguard Home
- Domain name reservation via `external-dns.alpha.kubernetes.io/hostname` annotation
	- Using `.home.arpa` TLD as recommended by RFC 8375
	- L4 external endpoints
- L7 Gateway API via HTTPRoute
	- Using `.home.arpa` TLD as recommended by RFC 8375
	- Using Kubernetes Gateway API (stable channel) only to remain vendor-agnostic

## Temporary DNS server local override

Best solution would be to set upstream router's DNS server to point to the DNS server deployed in the cluster.
- Multiple DNS servers are treated equally without preference nor priority
	- Unless explicitly configured for split DNS
- Upstream router must be configured to only use internal DNS server
	- DNS resolution fails if internal DNS is offline
	- Not safe during testing

Until homelab stabilizes, manual local override is sufficient.

```bash
# For systemd-based system
# Tested on Fedora 43
# Reference: https://man7.org/linux/man-pages/man5/systemd.dns-delegate.5.html
sudo -i

mkdir -p /etc/systemd/dns-delegate.d

cat <<EOF > /etc/systemd/dns-delegate.d/home-arpa.dns-delegate
[Delegate]
DNS=<IP of DNS server>
Domains=~home.arpa
EOF

systemctl reload systemd-resolved
```

## Gateway API

Benefit of Gateway API
- Reduce IP address consumption for web services
	- Important for homelab where subnet may be shared with other physical devices
- Control network exposure of application containers

Gateway API v1 currently makes 2+3 route types available
- Stable channel
	- HTTP
	- GRPC
- Experimental channel
	- TCP
	- UDP
	- TLS

### Plans for future

L4 routing is experimental and is not used in this setup. However, if it becomes stable, it would be a better alternative to IP allocation.

TCP / UDP has no discriminators like L7 hostname fields, so they must listen on distinct ports.
- IP in typical /24 subnet: 254 addresses are available
	- Exclude gateway + broadcast address
- L4 in typical system: 64,512 ports are available
	- Exclude ports reserved for system services

If exposing L4 service is required, `<gateway address>:<port>` offers more addressable range than a unique IP per service. For this reason, having a stable gateway address is beneficial
- `spec.addresses` [(doc](https://gateway-api.sigs.k8s.io/reference/spec/#gatewayspecaddress)) does not seem to be supported by [external-dns](https://kubernetes-sigs.github.io/external-dns/latest/docs/sources/gateway-api/) yet
- `spec.infrastructure.annotations` ([doc](https://gateway-api.sigs.k8s.io/reference/spec/#gatewayinfrastructure)) instead applies the external-dns annotation to the generated loadbalancer service
	- This also applies the annotation to the pod so external-dns must be configured to ignore pod annotations
		- This is the default behavior

### Implementation choice

Initial choice was [Traefik](https://doc.traefik.io/traefik/setup/kubernetes/) as it seems to be the popular choice in homelabs.
- Configuring it was a hassle and having some features behind a paywall didn't seem worth the trouble
- [Benchmark](https://github.com/howardjohn/gateway-api-bench) shows concerning results

Based on the benchmark above, I switched to [Istio](https://istio.io/latest/docs/ambient/)
- Initial setup was easier, but partially missing documentation
	- Privileged namespace requirement and deployment recommendation is unclear
		- [Docs suggest only for GKE platform](https://istio.io/latest/docs/ambient/install/platform-prerequisites/#google-kubernetes-engine-gke)
		- [Github Chart suggest only for cni but not ztunnel](https://github.com/istio/istio/tree/master/manifests/charts/istio-cni#installing-the-chart)
	- No documentation that states the `istiod` config required when deploying privileged components to another namespace
		- `trustedZtunnelNamespace` must be set otherwise pods fail to become ready
- Default config uses a lot of memory
	- Initial deployment failed on some VM nodes due to insufficient RAM
		- Resolved by reducing memory requirements via config
