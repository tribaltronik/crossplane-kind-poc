# Crossplane Kind PoC

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.30+-blue)](https://kind.sigs.k8s.io/)
[![Crossplane](https://img.shields.io/badge/Crossplane-1.17+-blue)](https://crossplane.io/)

A fully local, laptop-friendly demonstration of **Crossplane** as a universal control plane running on **Kind** (Kubernetes-in-Docker). This PoC shows how to manage "anything" declaratively using custom APIs, Compositions, and Providers — perfect for learning Platform Engineering.

**Zero cloud cost. Full GitOps. Self-service infrastructure.**

## ✨ Features

- **Kind cluster** with optimized config
- **Crossplane core** + `provider-kubernetes`, `provider-helm`, `provider-nop`
- Custom XRDs & Compositions for:
  - Simple Apps (Deployment + Service)
  - Full Platform Environments (App + Database + Networking)
- Self-service **Claims** (`kubectl apply -f myapp.yaml`)
- **Composition Functions** example
- **ArgoCD GitOps** integration
- Configuration packaging ready for sharing
- Comprehensive scripts and documentation

## 📋 Quick Start

### 1. Prerequisites
- Docker Desktop / Podman
- `kubectl`, `helm`, `kind`, `crossplane` CLI
- 8GB+ RAM, 4+ CPU cores recommended

### 2. Clone & Bootstrap
```bash
git clone https://github.com/YOUR_USERNAME/crossplane-kind-poc.git
cd crossplane-kind-poc

# One-command setup
make cluster-up          # or ./scripts/setup.sh
make apply-basic         # Apply example claims
```

### 3. Try It
```bash
kubectl apply -f crossplane/claims/simple-app.yaml
kubectl get xsimpleapps -w
kubectl get deployment,svc -n my-app
```

See [docs/demo.md](docs/demo.md) for full walkthrough.

## 🏗️ Architecture

See **[architecture.md](docs/architecture.md)** for detailed diagrams and explanations.

## 📁 Project Structure

```
crossplane-kind-poc/
├── cluster/              # Kind cluster configuration
├── crossplane/
│   ├── providers/        # Provider and ProviderConfig YAMLs
│   ├── xrds/             # Composite Resource Definitions
│   ├── compositions/     # Implementation logic + patches
│   ├── claims/           # Example user claims
│   ├── functions/        # Custom Composition Functions
│   └── configs/          # Crossplane Configuration packages
├── argocd/               # GitOps manifests
├── scripts/              # setup, teardown, demo scripts
├── docs/                 # architecture, demo, troubleshooting
├── Makefile
└── README.md
```

## 🚀 What You'll Learn

- Writing effective XRDs and Compositions
- Using `provider-kubernetes` to manage any K8s resource
- Integrating Helm charts via `provider-helm`
- Building self-service platforms with Claims
- GitOps best practices with ArgoCD
- Local testing with `crossplane beta render`

## 🛠️ Make Commands

- `make cluster-up` – Create Kind cluster + install everything
- `make cluster-down` – Clean teardown
- `make apply-basic` – Deploy simple app example
- `make apply-platform` – Deploy full environment
- `make render` – Test compositions locally
- `make status` – Show Crossplane resource status

## 📈 Roadmap

- [x] Basic setup
- [x] Simple App Composition
- [ ] Advanced Platform Environment
- [ ] Composition Functions
- [ ] Full ArgoCD GitOps
- [ ] Configuration packaging

## 🤝 Contributing / Extending

Fork this repo and extend it! Great next steps:
- Add AWS/GCP providers with LocalStack simulation
- Implement policy-as-code
- Add observability stack

## 📄 Documentation

- [spec.md](spec.md) – Detailed specification
- [plan.md](plan.md) – Implementation roadmap
- [architecture.md](docs/architecture.md) – Diagrams & deep dive
- [docs/demo.md](docs/demo.md) – Step-by-step demo

---

**Made with ❤️ for Platform Engineering enthusiasts**

*This PoC is designed to run entirely on a laptop while mirroring real-world production patterns.*