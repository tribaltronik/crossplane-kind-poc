# Crossplane Kind PoC Implementation Plan (Agentic)

This document outlines a step-by-step, agent-friendly plan for building the PoC. It is structured for iterative development, allowing an AI agent (or human) to implement one section at a time with clear verification steps.

## Phase 0: Repository Setup
1. Create GitHub repo `crossplane-kind-poc`.
2. Initialize directory structure (see spec.md).
3. Add `.gitignore`, LICENSE, initial README.md skeleton.
4. Commit baseline.

**Verification**: Repo exists with correct folders.

## Phase 1: Local Cluster & Crossplane Bootstrap
**Agent Tasks**:
- Create `cluster/kind-config.yaml` (multi-node, port mappings, resource requests).
- Write `scripts/setup.sh`:
  - kind create cluster
  - Install Crossplane via Helm
  - Install providers (kubernetes, helm, nop)
  - Apply ProviderConfigs
- Write `scripts/teardown.sh`
- Create Makefile targets: `make cluster-up`, `make cluster-down`

**Verification**:
- `kubectl get ns crossplane-system` shows healthy pods.
- `kubectl crossplane get providers` shows Installed/Healthy.

**Estimated Effort**: 2-4 hours

## Phase 2: Basic Kubernetes Provider Composition
**Agent Tasks**:
- Define XRD: `XSimpleApp` / Claim: `SimpleApp`
  - Parameters: image, replicas, port, namespace
- Composition using provider-kubernetes:
  - Creates Namespace, Deployment, Service, (optional Ingress)
- Patches for name propagation, labels, etc.
- Example claim in `crossplane/claims/simple-app.yaml`

**Verification**:
- `kubectl apply -f claim.yaml`
- Resources appear and reach Ready state.
- Use `crossplane beta render` to validate.

**Estimated Effort**: 3-5 hours

## Phase 3: Advanced Composite + Helm Integration
**Agent Tasks**:
- New XRD: `XPlatformEnv` / Claim: `PlatformEnv`
  - Parameters: appImage, dbType (postgres/redis), environment
- Composition that orchestrates:
  - Namespace
  - HelmRelease for database (via provider-helm)
  - Kubernetes resources for app
  - NetworkPolicy, ConfigMap for connection strings
- Use patchSets, transforms, and readiness checks.

**Verification**:
- Full environment spins up from one Claim.
- App can connect to DB (simple test deployment).

**Estimated Effort**: 5-8 hours

## Phase 4: Composition Functions
**Agent Tasks**:
- Implement a simple Function (recommend Go template or Python/KCL).
- Example: Dynamic naming, conditional resource inclusion, secret injection logic.
- Register Function and use in Composition.

**Verification**:
- Function builds and runs in cluster.
- Render + apply shows dynamic behavior.

**Estimated Effort**: 4-6 hours

## Phase 5: GitOps with ArgoCD
**Agent Tasks**:
- Install ArgoCD manifests.
- Create Application / ApplicationSet for Crossplane configs.
- Bootstrap ArgoCD to manage itself and Crossplane resources.

**Verification**:
- Changes in repo automatically sync to cluster.

**Estimated Effort**: 3-5 hours

## Phase 6: Packaging & Observability
**Agent Tasks**:
- Create Crossplane Configuration package.
- Add status condition examples and troubleshooting guide.
- EnvironmentConfig for shared settings.

**Verification**:
- Package builds and installs cleanly.

**Estimated Effort**: 2-4 hours

## Phase 7: Documentation & Polish
**Agent Tasks**:
- Write full README.md with badges, quickstart, architecture diagram (Mermaid).
- Create `docs/architecture.md` and `docs/demo.md`.
- Add GIFs/screenshots (record with asciinema or terminal GIF tools).
- Write comprehensive demo script.
- Add tests (basic bash or kuttl).

**Verification**:
- New user can follow README and succeed.
- Repo looks professional.

**Estimated Effort**: 4-6 hours

## Overall Timeline
- **MVP (Phases 0-2 + basic docs)**: 1 weekend
- **Full PoC**: 2-3 weekends

## Agentic Workflow Recommendations
- Work in small PRs or branches per phase.
- Use `crossplane beta render` heavily for fast feedback.
- After each phase: Update README, commit with clear message, test full flow.
- Include troubleshooting section in docs.
- For any YAML generation: Follow Crossplane best practices (composition revisions, deletion policies, etc.).

## Risks & Mitigations
- Resource exhaustion on laptop → Document min requirements, add limits.
- Provider version conflicts → Pin versions in scripts.
- ArgoCD sync loops → Start with manual apply, then enable GitOps.

This plan is executable sequentially. Start with Phase 0 and proceed phase-by-phase, verifying at each step.