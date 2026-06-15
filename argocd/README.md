# ArgoCD

This directory contains the ArgoCD GitOps setup for the crossplane-kind-poc project.

## Install

Run `install.sh` to deploy ArgoCD v2.12.0 into the `argocd` namespace:

```bash
./argocd/install.sh
```

After installation, access the ArgoCD UI:

```bash
kubectl port-forward -n argocd svc/argocd-server 8080:443
```

The initial admin password is the name of the `argocd-initial-admin-secret` Secret:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

## Application

`app-crossplane.yaml` defines an ArgoCD Application that syncs the `crossplane/` directory from this repo into the `crossplane-system` namespace. It uses automated sync with prune and self-heal enabled.

Before applying, replace `YOUR_USERNAME` in the repoURL with your GitHub username.
