# Crossplane Kind PoC Specification

## Project Overview
**Project Name**: crossplane-kind-poc  
**Description**: A self-contained, local demonstration of Crossplane as a universal control plane running on Kubernetes-in-Docker (Kind). This PoC showcases how to manage "anything" (Kubernetes-native resources, Helm charts, and custom compositions) entirely on a laptop. It serves as a strong portfolio piece demonstrating Platform Engineering, GitOps, and Infrastructure as Code (IaC) principles using Crossplane.

**Goals**:
- Prove Crossplane can act as a control plane for local infrastructure.
- Provide a reproducible setup for developers to experiment with XRDs, Compositions, Claims, Providers, and Functions.
- Highlight best practices: declarative configs, GitOps with ArgoCD, observability, and packaging.
- Zero cloud cost – everything runs locally.
- Easy to extend to real cloud providers (AWS, GCP, Azure) by swapping ProviderConfigs.

**Target Audience**: Platform Engineers, SREs, DevOps practitioners, and hiring managers reviewing GitHub portfolios.

## Scope
**In Scope**:
- Kind cluster bootstrap with resource limits.
- Crossplane core + essential providers (kubernetes, helm, nop).
- Custom XRDs and Compositions for:
  - Simple Kubernetes apps (Deployment + Service + Namespace).
  - Composite application environments (app + DB + observability).
- Claims API for self-service provisioning.
- Composition Functions (at least one example).
- ArgoCD for GitOps management of Crossplane resources.
- Configuration packaging.
- Comprehensive documentation and demo scripts.

**Out of Scope** (for initial PoC):
- Full cloud provider integration (but documented as extension).
- Production-grade security / RBAC multi-tenancy.
- Advanced observability dashboards.
- CI/CD pipelines beyond local scripts.

## Architecture
- **Cluster**: Kind (multi-node recommended).
- **Control Plane**: Crossplane in `crossplane-system` namespace.
- **Providers**:
  - provider-kubernetes: Manage K8s resources declaratively.
  - provider-helm: Deploy packaged apps/DBs.
  - provider-nop: For testing.
- **API Layer**: XRDs define custom APIs; Compositions implement them.
- **GitOps**: ArgoCD ApplicationSets or Apps syncing from this repo.
- **User Experience**: `kubectl apply -f claim.yaml` → resources provisioned automatically.

**High-Level Flow**:
1. User applies a Claim.
2. Crossplane reconciles via Composition.
3. Providers create underlying resources (Pods, Helm releases, etc.).
4. Status conditions and observed generation provide visibility.

## Key Features / Deliverables
1. **Bootstrap Scripts**: `scripts/setup.sh`, `scripts/teardown.sh`.
2. **Core Configurations**:
   - XRDs in `crossplane/xrds/`
   - Compositions in `crossplane/compositions/`
   - Claims examples in `crossplane/claims/`
3. **Providers Setup**: Ready-to-apply Provider + ProviderConfig YAMLs.
4. **ArgoCD Integration**: Manifests in `argocd/`.
5. **Functions**: At least one Go or Python-based Composition Function.
6. **Documentation**:
   - Detailed README.md
   - architecture.md with Mermaid diagrams
   - demo.md with step-by-step + expected outputs
7. **Makefile / justfile**: Common tasks (up, down, apply-claim, render, test).

## Non-Functional Requirements
- **Reproducibility**: One-command setup where possible.
- **Resource Efficiency**: Works on laptop with 8GB+ RAM.
- **Clean State**: Easy to reset cluster.
- **Extensibility**: Modular structure for adding new Compositions.
- **Portfolio Polish**: Professional README, diagrams, GIFs/screenshots, clear commit history.

## Success Criteria
- Applying a Claim creates a full environment (app + DB) visible in `kubectl get`.
- ArgoCD successfully syncs all Crossplane objects.
- `crossplane beta render` works for local validation.
- Documentation allows a new user to run the PoC in <15 minutes.

## Future Extensions
- Add AWS provider with localstack simulation.
- Implement policy-as-code with Kyverno or Gatekeeper.
- Multi-cluster management via provider-kubernetes.

