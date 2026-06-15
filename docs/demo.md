# Crossplane Kind PoC — Demo Walkthrough

This guide walks through a complete demo of the Crossplane Kind PoC,
from cluster bootstrap to teardown.

For background, see [spec.md](spec.md) and [architecture.md](architecture.md).

## Prerequisites

- **Docker Desktop** (or Podman) — 8GB+ RAM recommended
- **kind** — `brew install kind`
- **kubectl** — `brew install kubectl`
- **helm** — `brew install helm`
- **crossplane CLI** — `brew install crossplane`

Verify everything is installed:

```bash
kind version
kubectl version --client
helm version
crossplane --version
```

## Step-by-Step

### 1. Clone & Bootstrap Cluster

```bash
git clone https://github.com/YOUR_USERNAME/crossplane-kind-poc.git
cd crossplane-kind-poc

# One-command cluster creation + Crossplane + providers
make cluster-up
```

This runs `scripts/setup.sh`, which:
- Creates a 2-node Kind cluster
- Installs Crossplane via Helm
- Installs `provider-kubernetes`, `provider-helm`, `provider-nop`
- Applies ProviderConfigs

Expected output (abbreviated):

```
Creating cluster "kind" ...
 ✓ Ensuring node image (kindest/node:v1.30.0) 🖼
 ✓ Preparing nodes 📦 📦
 ✓ Writing configuration 📜
 ✓ Starting control-plane 🕹️
 ✓ Installing CNI 🔌
 ✓ Installing StorageClass 💾
 ✓ Joining worker node 🚜
Set kubectl context to "kind-kind"
Crossplane installed in namespace crossplane-system
Providers installed and healthy
```

### 2. Deploy a SimpleApp

```bash
make apply-basic
```

This applies `crossplane/claims/simple-app.yaml`:

```yaml
apiVersion: example.com/v1alpha1
kind: SimpleApp
metadata:
  name: my-simple-app
spec:
  parameters:
    image: nginx:latest
    replicas: 2
    port: 80
    namespace: my-app
```

### 3. Verify SimpleApp Resources

After a few seconds, check the created resources:

```bash
kubectl get deployment,svc -n my-app
```

Expected output:

```
NAME                            READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/my-simple-app   2/2     2            2           30s

NAME                    TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
service/my-simple-app   ClusterIP   10.96.100.50    <none>        80/TCP    30s
```

### 4. Validate SimpleApp Locally

```bash
make render-simple
```

Expected output contains rendered Namespace, Deployment, and Service manifests
with your claim's parameters injected.

### 5. Deploy a Platform Environment

```bash
make apply-platform
```

This applies `crossplane/claims/platform-env.yaml`:

```yaml
apiVersion: example.com/v1alpha1
kind: PlatformEnv
metadata:
  name: my-dev-env
spec:
  parameters:
    appImage: nginx:latest
    dbType: postgres
    environment: dev
```

Crossplane will create:
- A Namespace (`dev`)
- A HelmRelease for PostgreSQL
- A Deployment for the app
- A Service for the app
- A ConfigMap with connection strings
- A NetworkPolicy

### 6. Verify Platform Environment

```bash
kubectl get helmrelease
```

Expected output:

```
NAME   READY   STATUS   AGE
dev    True    sync     45s
```

```bash
kubectl get deployment,svc,configmap,networkpolicy -n dev
```

Expected output:

```
NAME                       READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/app        1/1     1            1           45s

NAME            TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
service/app     ClusterIP   10.96.200.10    <none>        80/TCP    45s

NAME                DATA   AGE
configmap/app-config   2    45s

NAME                                        POD-SELECTOR   AGE
networkpolicy.networking.k8s.io/app-network-policy   <none>   45s
```

### 7. Validate Platform Environment Locally

```bash
make render-platform
```

Expected output contains rendered Namespace, HelmRelease, Deployment, Service,
ConfigMap, and NetworkPolicy manifests.

### 8. Cleanup

```bash
make cluster-down
```

This destroys the entire Kind cluster and all resources.

```bash
kind get clusters
# Expected: "No kind clusters found."
```

## Custom Claims

You can create your own claims:

```bash
cat <<EOF | kubectl apply -f -
apiVersion: example.com/v1alpha1
kind: SimpleApp
metadata:
  name: my-custom-app
spec:
  parameters:
    image: caddy:latest
    replicas: 1
    port: 8080
    namespace: custom-ns
EOF
```

## Next Steps

- Read the [architecture](architecture.md) for design details
- Check [spec.md](spec.md) for the full project scope
- Browse `crossplane/xrds/` and `crossplane/compositions/` for reusable patterns
- Extend with real cloud providers or additional compositions
