# Ralph-Loop Implementation Plan

Two-agent iterative build plan for the Crossplane Kind PoC.

---

## The Loop Protocol

Each atomic task follows this sequence:

```
┌─────────────────────────────────────────────────────┐
│  ┌──────────┐    implements     ┌────────────┐      │
│  │  Ralph   │ ────────────────▶ │  Verifier  │      │
│  │ (writer) │                   │ (checker)  │      │
│  └──────────┘ ◀──────────────── └────────────┘      │
│                   reports diffs                      │
│                     or passes                        │
│                                                      │
│  Loop until Verifier passes all acceptance criteria  │
└─────────────────────────────────────────────────────┘
```

**Ralph** — creates/modifies files, runs shell commands, performs operations.
**Verifier** — runs acceptance checks after each task. Never creates or modifies anything.

### Loop rules

- Verifier runs its **full checklist** every iteration. No partial passes.
- Every checklist item is either **✅ Pass** or **❌ Fail**. No "mostly passes."
- If an item fails, Verifier reports the **exact failure reason** and **which file/line**.
- Ralph fixes the specific failure and re-invites Verifier.
- **After 3 consecutive loops on the same task**, escalate to the user: report what changed each loop and what still fails.
- If a task has **environment-dependent** checks (e.g., needs Docker/Kind), Verifier checks what it can from file content alone, marks integration steps as `[requires Docker/Kind — skip if unavailable]`, and Ralph runs those separately.

### Task structure

Each task has:
- **What Ralph creates/modifies** — exact file paths
- **Acceptance checklist** — atomic pass/fail items, grouped as:
  - *File checks* (always runnable)
  - *Integration checks* (conditional on environment)
- **Edge cases** — known pitfalls Ralph should avoid

---

## Phase 0 — Repository Setup

### Task 0.1 — Create directory structure

**Ralph creates** these directories (with `.gitkeep` files for empty dirs):

```
cluster/
crossplane/providers/
crossplane/xrds/
crossplane/compositions/
crossplane/claims/
crossplane/functions/
crossplane/configs/
argocd/
scripts/
```

**Must preserve**: `README.md`, `docs/architecture.md`, `docs/plan.md`, `docs/spec.md`, `docs/ralph-loop-plan.md` — do not delete, move, or modify them.

**Edge cases:**
- Directories already exist from a prior run → skip creation, do not fail
- `.gitkeep` files must be present so git tracks empty dirs

**Acceptance checklist:**

*File checks:*
- [ ] `cluster/` exists
- [ ] `crossplane/providers/` exists
- [ ] `crossplane/xrds/` exists
- [ ] `crossplane/compositions/` exists
- [ ] `crossplane/claims/` exists
- [ ] `crossplane/functions/` exists
- [ ] `crossplane/configs/` exists
- [ ] `argocd/` exists
- [ ] `scripts/` exists
- [ ] `docs/architecture.md` still exists and is unchanged
- [ ] `docs/plan.md` still exists and is unchanged
- [ ] `docs/spec.md` still exists and is unchanged
- [ ] `README.md` still exists and is unchanged
- [ ] `git status` shows only new added files (no deletions)

---

### Task 0.2 — Add `.gitignore` and `LICENSE`

**Ralph creates** `.gitignore` and `LICENSE` at the repo root.

`.gitignore` must cover: `*.tfstate`, `*.tfstate.*`, `.terraform/`, `*.log`, `.DS_Store`, `node_modules/`, `.idea/`, `*.secret.yaml`, `*.tmp`, `.env`, `*.local`.

`LICENSE` must be Apache 2.0 with year and placeholder author.

**Edge cases:**
- If `.gitignore` or `LICENSE` already exist, overwrite with correct content

**Acceptance checklist:**

*File checks:*
- [ ] `.gitignore` exists at repo root
- [ ] `.gitignore` contains entries for `.DS_Store`, `*.log`, `node_modules/`, `.idea/`, `*.secret.yaml`, `.env`, `.terraform/`, `*.tfstate`
- [ ] `LICENSE` exists at repo root
- [ ] `LICENSE` is Apache 2.0 (contains `Apache License, Version 2.0` header)
- [ ] `docs/` and `README.md` are still unchanged (verify with `git diff --name-only`)

---

### Task 0.3 — Baseline commit

**Ralph runs:**
```bash
git add -A
git commit -m "feat: scaffold repository structure"
```

**Edge cases:**
- Nothing to commit (already committed) → mark as skipped, explain why

**Acceptance checklist:**

*File checks:*
- [ ] `git log --oneline -1` contains `feat: scaffold repository structure`
- [ ] `git status` is clean
- [ ] All Phase 0 directories are tracked (`git ls-files cluster/ crossplane/ argocd/ scripts/` shows files inside them)
- [ ] `.gitignore` is tracked
- [ ] `LICENSE` is tracked

---

## Phase 1 — Local Cluster & Crossplane Bootstrap

### Task 1.1 — Create `cluster/kind-config.yaml`

**Ralph creates** `cluster/kind-config.yaml` with:
- `kind: Cluster`, `apiVersion: kind.x-k8s.io/v1alpha4`
- 1 control-plane node + 1 worker node
- Port mappings: host `80` → container `80`, host `443` → container `443`
- `kubeProxyMode: iptables`
- `kubeadmConfigPatches` with laptop-friendly resource limits (e.g., `kubeReserved`)

**Edge cases:**
- If the file already exists, overwrite it

**Acceptance checklist:**

*File checks:*
- [ ] `cluster/kind-config.yaml` exists
- [ ] Parses as valid YAML (`python3 -c "import yaml; yaml.safe_load(open('cluster/kind-config.yaml'))"`)
- [ ] `kind: Cluster` present
- [ ] `apiVersion: kind.x-k8s.io/v1alpha4` present
- [ ] Exactly 2 nodes defined: 1 control-plane, 1 worker
- [ ] Port mapping exists for `hostPort: 80`, `containerPort: 80`
- [ ] Port mapping exists for `hostPort: 443`, `containerPort: 443`
- [ ] Node has `role: control-plane`
- [ ] Node has `role: worker`

---

### Task 1.2 — Write `scripts/setup.sh`

**Ralph creates** `scripts/setup.sh` — a bash script that automates the full cluster bootstrap.

Must include:
1. `#!/usr/bin/env bash` + `set -euo pipefail`
2. Check prerequisites (kind, kubectl, helm, crossplane CLI exist)
3. `kind create cluster --config cluster/kind-config.yaml` with `--wait 5m`
4. `kubectl cluster-info --context kind-kind` to verify connection
5. `helm repo add crossplane-stable https://charts.crossplane.io/stable`
6. `helm repo update`
7. `helm install crossplane crossplane-stable/crossplane --namespace crossplane-system --create-namespace --wait` with a pinned chart version
8. `kubectl wait --for=condition=available deployment/crossplane --namespace crossplane-system --timeout=5m`
9. Install providers via `kubectl apply -f crossplane/providers/` (will be created in Task 1.4)
10. Wait for providers to be healthy
11. Print summary of installed components

**Edge cases:**
- Script should exit with clear error if a prerequisite is missing
- Should be idempotent (safe to re-run if cluster already exists)

**Acceptance checklist:**

*File checks:*
- [ ] `scripts/setup.sh` exists
- [ ] `stat -f "%A" scripts/setup.sh` shows executable bit (755 or similar)
- [ ] First line is `#!/usr/bin/env bash`
- [ ] Contains `set -euo pipefail`
- [ ] Contains `kind create cluster` with `--config cluster/kind-config.yaml`
- [ ] Contains `helm repo add crossplane-stable`
- [ ] Contains `helm install crossplane`
- [ ] `shellcheck scripts/setup.sh` passes with no errors or warnings
- [ ] Script has a prerequisite check (`command -v kind`, etc.)
- [ ] Script applies `crossplane/providers/` directory

---

### Task 1.3 — Write `scripts/teardown.sh`

**Ralph creates** `scripts/teardown.sh` — destroys the cluster.

Must include:
1. `#!/usr/bin/env bash` + `set -euo pipefail`
2. `kind delete cluster --name kind`
3. Optional: remove `~/.kube/config` backup or log message

**Acceptance checklist:**

*File checks:*
- [ ] `scripts/teardown.sh` exists and is executable
- [ ] Contains `kind delete cluster`
- [ ] `shellcheck scripts/teardown.sh` passes

---

### Task 1.4 — Create provider manifests under `crossplane/providers/`

**Ralph creates** these files:

- `crossplane/providers/provider-kubernetes.yaml` — `Provider` (pkg.crossplane.io/v1) + `ProviderConfig` (kubernetes.crossplane.io/v1alpha1, InCluster)
- `crossplane/providers/provider-helm.yaml` — `Provider` + `ProviderConfig` (helm.crossplane.io/v1beta1, InCluster)
- `crossplane/providers/provider-nop.yaml` — `Provider` only (no ProviderConfig needed)

Each `Provider` must:
- Use `spec.package` with pinned version (e.g., `xpkg.upbound.io/crossplane-contrib/provider-kubernetes:v0.12.0`)
- Optionally use `spec.controllerConfig` referencing a `DeploymentRuntimeConfig` (can omit for simplicity)

Each `ProviderConfig` must:
- Reference the correct provider type
- Use `spec.credentials.source: InjectedIdentity` (for in-cluster)

**Edge cases:**
- Versions should be the latest stable compatible with Crossplane 1.17
- If a ProviderConfig is not needed (nop), do not create one

**Acceptance checklist:**

*File checks:*
- [ ] `crossplane/providers/provider-kubernetes.yaml` exists
- [ ] `crossplane/providers/provider-helm.yaml` exists
- [ ] `crossplane/providers/provider-nop.yaml` exists
- [ ] Each file is valid YAML
- [ ] provider-kubernetes has `apiVersion: pkg.crossplane.io/v1`, `kind: Provider`
- [ ] provider-kubernetes has a matching `ProviderConfig` (`kind: ProviderConfig`, `apiVersion: kubernetes.crossplane.io/v1alpha1`)
- [ ] provider-helm has `apiVersion: pkg.crossplane.io/v1`, `kind: Provider`
- [ ] provider-helm has a matching `ProviderConfig` (`kind: ProviderConfig`, `apiVersion: helm.crossplane.io/v1beta1`)
- [ ] provider-nop has `apiVersion: pkg.crossplane.io/v1`, `kind: Provider`
- [ ] provider-nop does NOT have a ProviderConfig (not needed)
- [ ] All provider packages have pinned versions (e.g., `:v0.12.0`, not `:latest`)
- [ ] All ProviderConfigs use `spec.credentials.source: InjectedIdentity`
- [ ] `kubectl apply --dry-run=client -f crossplane/providers/provider-kubernetes.yaml` passes
- [ ] `kubectl apply --dry-run=client -f crossplane/providers/provider-helm.yaml` passes
- [ ] `kubectl apply --dry-run=client -f crossplane/providers/provider-nop.yaml` passes

---

### Task 1.5 — Create `Makefile`

**Ralph creates** `Makefile` at repo root with targets:

| Target | Action |
|---|---|
| `cluster-up` | `scripts/setup.sh` |
| `cluster-down` | `scripts/teardown.sh` |
| `status` | Show Crossplane providers + providerconfigs |
| `render` | Placeholder: `echo "Usage: crossplane beta render crossplane/claims/<file>"` |
| `apply-basic` | Placeholder (implemented in Phase 2) |
| `apply-platform` | Placeholder (implemented in Phase 3) |
| `help` | List all targets with descriptions |

Use `.PHONY` for all targets.

**Edge cases:**
- Existing Makefile → overwrite with full content
- `cluster-up` must depend on `cluster/kind-config.yaml` and `scripts/setup.sh` existing (fail with helpful message if not)

**Acceptance checklist:**

*File checks:*
- [ ] `Makefile` exists at repo root
- [ ] `make cluster-up` target exists (check with `make -qp | grep -E '^cluster-up:'`)
- [ ] `make cluster-up` invokes `scripts/setup.sh`
- [ ] `make cluster-down` target exists
- [ ] `make cluster-down` invokes `scripts/teardown.sh`
- [ ] `make status` target exists
- [ ] `make status` invokes `kubectl get provider,providerconfig`
- [ ] `make help` target exists and lists all targets
- [ ] `.PHONY` declared for all targets
- [ ] `make -n cluster-up` runs without error (dry-run check)

---

### Task 1.6 — Integration test: bootstrap script

**[requires Docker/Kind — skip if unavailable]**

**Ralph runs** `make cluster-up` on a machine with Docker, kind, kubectl, helm, crossplane CLI.

**Acceptance checklist:**

*File checks (always runnable):*
- [ ] `scripts/setup.sh` is syntactically valid (`bash -n scripts/setup.sh`)
- [ ] `scripts/setup.sh` uses `set -euo pipefail`
- [ ] All referenced files (`cluster/kind-config.yaml`, `crossplane/providers/*`) exist

*Integration checks (Docker required):*
- [ ] `kind get clusters` shows at least 1 cluster
- [ ] `kubectl get ns crossplane-system` returns `Active`
- [ ] `kubectl get pods -n crossplane-system` shows all pods `Running`/`Ready`
- [ ] `kubectl crossplane get providers` shows all 3 providers as `Installed` and `Healthy`
- [ ] `make cluster-down` runs without error
- [ ] `kind get clusters` shows no clusters after teardown

---

## Phase 2 — Basic Kubernetes Provider Composition

### Task 2.1 — Create XRD for `XSimpleApp`

**Ralph creates** `crossplane/xrds/xsimpleapp.yaml`.

API surface:
- Group: `example.com`
- Composite kind: `XSimpleApp` (plural: `xsimpleapps`)
- Claim kind: `SimpleApp` (plural: `simpleapps`)
- Version: `v1alpha1`
- Schema parameters:
  - `image`: type string, required
  - `replicas`: type integer, default 1, minimum 1
  - `port`: type integer, default 80
  - `namespace`: type string, required

**Edge cases:**
- Use `default` and `minimum` for validation
- `served: true`, `referenceable: true` on the version

**Acceptance checklist:**

*File checks:*
- [ ] `crossplane/xrds/xsimpleapp.yaml` exists
- [ ] Valid YAML
- [ ] `apiVersion: apiextensions.crossplane.io/v1`
- [ ] `kind: CompositeResourceDefinition`
- [ ] `spec.group: example.com`
- [ ] `spec.names.kind: XSimpleApp`
- [ ] `spec.names.plural: xsimpleapps`
- [ ] `spec.claimNames.kind: SimpleApp`
- [ ] `spec.claimNames.plural: simpleapps`
- [ ] `spec.versions[0].name: v1alpha1`
- [ ] `spec.versions[0].served: true`
- [ ] `spec.versions[0].referenceable: true`
- [ ] Schema has `image` (type string, in spec.parameters)
- [ ] Schema has `replicas` (type integer, default 1, minimum 1)
- [ ] Schema has `port` (type integer, default 80)
- [ ] Schema has `namespace` (type string)
- [ ] `kubectl apply --dry-run=client -f crossplane/xrds/xsimpleapp.yaml` passes

---

### Task 2.2 — Create Composition for `XSimpleApp`

**Ralph creates** `crossplane/compositions/xsimpleapp.yaml` using `provider-kubernetes`.

Must provision:
1. **Namespace** — from `spec.parameters.namespace`
2. **Deployment** — using `spec.parameters.image`, `spec.parameters.replicas`; labels from claim name
3. **Service** — port from `spec.parameters.port`, selector matching Deployment labels

Each resource must use `provider-kubernetes` and have proper patches connecting claim parameters to managed resource spec fields.

Use `spec.resources` with `base` + `patches[]` format (or the newer `spec.pipeline` format — be consistent).

**Edge cases:**
- Namespace creation must be first (Deployment/Service depend on it)
- Use `dependsOn` or proper ordering
- All resources must have `spec.writeConnectionSecretToRef` removed or omitted (not needed for PoC)

**Acceptance checklist:**

*File checks:*
- [ ] `crossplane/compositions/xsimpleapp.yaml` exists
- [ ] Valid YAML
- [ ] `apiVersion: apiextensions.crossplane.io/v1`
- [ ] `kind: Composition`
- [ ] `spec.compositeTypeRef.apiVersion: example.com/v1alpha1`
- [ ] `spec.compositeTypeRef.kind: XSimpleApp`
- [ ] Has `spec.resources` with 3 entries OR `spec.pipeline` with 3 steps (Namespace, Deployment, Service)
- [ ] Namespace resource uses `kind: Namespace`, `apiVersion: v1`
- [ ] Deployment resource uses `kind: Deployment`, `apiVersion: apps/v1`
- [ ] Service resource uses `kind: Service`, `apiVersion: v1`
- [ ] Each resource has `patches[]` with `type: FromCompositeFieldPath` or `type: ToCompositeFieldPath` as appropriate
- [ ] Namespace name is patched from `spec.parameters.namespace`
- [ ] Deployment image is patched from `spec.parameters.image`
- [ ] Deployment replicas is patched from `spec.parameters.replicas`
- [ ] Service port is patched from `spec.parameters.port`
- [ ] `kubectl apply --dry-run=client -f crossplane/compositions/xsimpleapp.yaml` passes

---

### Task 2.3 — Create example claim

**Ralph creates** `crossplane/claims/simple-app.yaml`:

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

**Acceptance checklist:**

*File checks:*
- [ ] `crossplane/claims/simple-app.yaml` exists
- [ ] Valid YAML
- [ ] `apiVersion: example.com/v1alpha1`
- [ ] `kind: SimpleApp`
- [ ] `spec.parameters.image`, `spec.parameters.replicas`, `spec.parameters.port`, `spec.parameters.namespace` are all present
- [ ] `replicas: 2`
- [ ] `kubectl apply --dry-run=client -f crossplane/claims/simple-app.yaml` passes

---

### Task 2.4 — Add Makefile targets and validate with render

**Ralph updates** `Makefile`:
- `apply-basic` → `kubectl apply -f crossplane/claims/simple-app.yaml`
- Update `render` → `crossplane beta render crossplane/claims/simple-app.yaml`

**Ralph runs** `crossplane beta render crossplane/claims/simple-app.yaml` (XRD + Composition must be discoverable).

**Acceptance checklist:**

*File checks:*
- [ ] `make apply-basic` target exists and invokes `kubectl apply -f crossplane/claims/simple-app.yaml`
- [ ] `make render` target invokes `crossplane beta render`

*Integration checks (requires crossplane CLI, not Docker):*
- [ ] `crossplane beta render` exits 0
- [ ] Render output contains a Namespace resource
- [ ] Render output contains a Deployment resource
- [ ] Render output contains a Service resource
- [ ] Render output shows `nginx:latest` as the image

---

### Task 2.5 — Integration test: apply and verify on cluster

**[requires Docker/Kind — skip if unavailable]**

**Ralph does** on a running cluster (from Phase 1):
```bash
kubectl apply -f crossplane/xrds/xsimpleapp.yaml
kubectl apply -f crossplane/compositions/xsimpleapp.yaml
kubectl apply -f crossplane/claims/simple-app.yaml
# Wait for resources
```

**Acceptance checklist:**

*Integration checks:*
- [ ] `kubectl get xrd` shows `xsimpleapps.example.com` with `ESTABLISHED: True`
- [ ] `kubectl get composition` shows the composition
- [ ] `kubectl get simpleapp` shows `NAME: my-simple-app`, `SYNCED: True`
- [ ] `kubectl get ns my-app` shows `Active`
- [ ] `kubectl get deployment -n my-app` shows `my-simple-app` with 2/2 replicas
- [ ] `kubectl get svc -n my-app` shows service with port 80

---

## Phase 3 — Advanced Composite + Helm Integration

### Task 3.1 — Create XRD for `XPlatformEnv`

**Ralph creates** `crossplane/xrds/xplatformenv.yaml`.

API surface:
- Group: `example.com`
- Composite kind: `XPlatformEnv` (plural: `xplatformenvs`)
- Claim kind: `PlatformEnv` (plural: `platformenvs`)
- Version: `v1alpha1`
- Parameters:
  - `appImage`: type string, required
  - `dbType`: type string, enum: `["postgres", "redis"]`
  - `environment`: type string, default `"dev"`

**Acceptance checklist:**

*File checks:*
- [ ] `crossplane/xrds/xplatformenv.yaml` exists
- [ ] Valid YAML
- [ ] `kind: CompositeResourceDefinition`
- [ ] `spec.group: example.com`
- [ ] `spec.names.kind: XPlatformEnv`
- [ ] `spec.claimNames.kind: PlatformEnv`
- [ ] `appImage` in schema, type string
- [ ] `dbType` in schema with `enum: ["postgres", "redis"]`
- [ ] `environment` in schema with `default: "dev"`
- [ ] `kubectl apply --dry-run=client` passes

---

### Task 3.2 — Create Composition for `XPlatformEnv`

**Ralph creates** `crossplane/compositions/xplatformenv.yaml` using both `provider-kubernetes` and `provider-helm`.

Must create:
1. Namespace (K8s)
2. HelmRelease for database using `provider-helm`:
   - If `dbType: postgres` → deploy bitnami/postgresql chart
   - If `dbType: redis` → deploy bitnami/redis chart
3. Deployment for the app (K8s)
4. Service for the app (K8s)
5. ConfigMap with connection strings (K8s)
6. NetworkPolicy (K8s)

Must use `patchSets` for reusable patch groups.

**Edge cases:**
- HelmRelease needs `spec.providerConfigRef.name` set to match the provider config name from Task 1.4
- Connection string in ConfigMap must be dynamically generated based on `dbType`
- Use `deletionPolicy: Delete` on managed resources

**Acceptance checklist:**

*File checks:*
- [ ] `crossplane/compositions/xplatformenv.yaml` exists
- [ ] Valid YAML
- [ ] `kind: Composition`
- [ ] `spec.compositeTypeRef.kind: XPlatformEnv`
- [ ] Has 6 resources in `spec.resources` OR 6 steps in `spec.pipeline`
- [ ] At least one resource is a HelmRelease (`apiVersion: helm.crossplane.io/v1beta1`, `kind: HelmRelease`)
- [ ] HelmRelease has `spec.providerConfigRef.name` set
- [ ] Includes ConfigMap resource with connection string patches
- [ ] Includes NetworkPolicy resource
- [ ] Uses `patchSets` (check `spec.patchSets` exists)
- [ ] `kubectl apply --dry-run=client` passes

---

### Task 3.3 — Create example claim

**Ralph creates** `crossplane/claims/platform-env.yaml`:

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

**Acceptance checklist:**

*File checks:*
- [ ] `crossplane/claims/platform-env.yaml` exists
- [ ] Valid YAML
- [ ] `kind: PlatformEnv`
- [ ] `spec.parameters.appImage`, `dbType`, `environment` all present
- [ ] `kubectl apply --dry-run=client` passes

---

### Task 3.4 — Add Makefile target and validate render

**Ralph updates** `Makefile`:
- `apply-platform` → `kubectl apply -f crossplane/claims/platform-env.yaml`
- Update `render` target to accept a CLAIM argument: `crossplane beta render $(CLAIM)`

**Ralph runs** `crossplane beta render crossplane/claims/platform-env.yaml`.

**Acceptance checklist:**

*File checks:*
- [ ] `make apply-platform` target exists and invokes `kubectl apply -f crossplane/claims/platform-env.yaml`
- [ ] `make render` accepts `CLAIM=` variable

*Integration checks (requires crossplane CLI):*
- [ ] `crossplane beta render crossplane/claims/platform-env.yaml` exits 0
- [ ] Output contains HelmRelease, Namespace, Deployment, Service, ConfigMap, NetworkPolicy

---

### Task 3.5 — Integration test: platform env on cluster

**[requires Docker/Kind — skip if unavailable]**

**Ralph** applies XRD, Composition, claim on a live cluster and waits for readiness.

**Acceptance checklist:**

*Integration checks:*
- [ ] `kubectl get xrd` shows `xplatformenvs.example.com` `ESTABLISHED: True`
- [ ] `kubectl get platformenv` shows `my-dev-env` `SYNCED: True`
- [ ] `kubectl get helmrelease` shows the database release `READY: True`
- [ ] App Deployment exists in the target namespace
- [ ] App Service exists in the target namespace
- [ ] ConfigMap exists with connection string content
- [ ] NetworkPolicy exists

---

## Phase 4 — Composition Functions

### Task 4.1 — Implement a Composition Function

**Ralph creates** a Composition Function in `crossplane/functions/`.

Choose one approach:
- **Go**: Use the Crossplane Function SDK template (preferred for production quality)
- **Python**: Use the Python Function SDK

The function should implement one of:
- Dynamic resource naming (e.g., append environment name to resource names)
- Conditional resource inclusion (e.g., include a monitoring sidecar based on `environment` parameter)
- Secret injection logic

Minimum structure:
- Source code with function logic
- `Dockerfile` for building
- Crossplane Function YAML manifest (`crossplane/functions/function.yaml`)

**Acceptance checklist:**

*File checks:*
- [ ] `crossplane/functions/` contains source code
- [ ] `crossplane/functions/` contains a `Dockerfile`
- [ ] `crossplane/functions/` contains a Function YAML (`apiVersion: pkg.crossplane.io/v1`, `kind: Function`)
- [ ] Function YAML has pinned image tag
- [ ] Function code compiles: `go build` passes if Go, or `python3 -m py_compile` passes if Python

---

### Task 4.2 — Wire Function into a Composition

**Ralph** creates or updates a Composition to use the Function via `spec.pipeline`.

**Ralph creates** `crossplane/functions/run.yaml` — a Function `DeploymentRuntimeConfig` if needed.

**Acceptance checklist:**

*File checks:*
- [ ] At least one Composition references the Function in its pipeline or resources
- [ ] The Composition is valid (`kubectl apply --dry-run=client` passes)
- [ ] The Function is deployable (Function YAML has correct runtime config)

---

### Task 4.3 — Test Function

**[requires Docker/Kind — skip if unavailable]**

**Ralph** deploys the Function, applies the updated Composition, and runs `crossplane beta render` + cluster apply.

**Acceptance checklist:**

*Integration checks:*
- [ ] `crossplane beta render` output shows the function's effect (e.g., dynamic naming, conditional resources)
- [ ] On cluster, Function pod is `Running`
- [ ] Function pod logs show no errors
- [ ] Claim using the Function-composition reaches `Ready` state
- [ ] Resources have the expected dynamic properties

---

## Phase 5 — GitOps with ArgoCD

### Task 5.1 — Create ArgoCD install manifests

**Ralph creates** `argocd/install.yaml` — either a single manifest or a reference to the ArgoCD Helm chart.

If using raw manifests:
- Download the official `install.yaml` from the ArgoCD releases page for a pinned version
- Place it in `argocd/install.yaml`
- Do NOT modify it (to keep upgrade path clean)

If using Helm:
- Create `argocd/argocd-helm.yaml` with `apiVersion: helm.crossplane.io/v1beta1`, `kind: HelmRelease` (reusing provider-helm)
- Or use `kubectl apply -f` approach in a script

**Edge cases:**
- Pin the ArgoCD version
- Include a namespace manifest for `argocd` if not included in the upstream install

**Acceptance checklist:**

*File checks:*
- [ ] `argocd/install.yaml` (or equivalent) exists
- [ ] Valid YAML
- [ ] Contains ArgoCD namespace (`argocd`) definition
- [ ] `kubectl apply --dry-run=client -f argocd/install.yaml` passes

---

### Task 5.2 — Create ArgoCD Application for Crossplane configs

**Ralph creates** `argocd/app-crossplane.yaml` — an ArgoCD Application that syncs `crossplane/` from this repo.

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: crossplane-configs
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/YOUR_USERNAME/crossplane-kind-poc.git
    targetRevision: HEAD
    path: crossplane/
  destination:
    server: https://kubernetes.default.svc
    namespace: crossplane-system
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

**Edge cases:**
- `repoURL` should be a placeholder (`REPO_URL` or `YOUR_USERNAME`) — Ralph should use a placeholder if the actual URL is unknown
- Add a note that the user must update `repoURL` before applying

**Acceptance checklist:**

*File checks:*
- [ ] `argocd/app-crossplane.yaml` exists
- [ ] Valid YAML
- [ ] `kind: Application`
- [ ] `spec.destination.server: https://kubernetes.default.svc`
- [ ] `spec.source.path: crossplane/`
- [ ] `spec.syncPolicy.automated.prune: true`
- [ ] `spec.syncPolicy.automated.selfHeal: true`
- [ ] `kubectl apply --dry-run=client` passes

---

### Task 5.3 — Bootstrap and verify GitOps sync

**[requires Docker/Kind — skip if unavailable]**

**Ralph** installs ArgoCD, applies the Application, and verifies auto-sync.

**Acceptance checklist:**

*Integration checks:*
- [ ] ArgoCD pods are running (`kubectl get pods -n argocd`)
- [ ] `argocd app list` or `kubectl get application -n argocd` shows the application
- [ ] Application status is `Synced`
- [ ] Application health is `Healthy`
- [ ] Crossplane resources managed by ArgoCD are in sync

---

## Phase 6 — Packaging & Observability

### Task 6.1 — Create Crossplane Configuration package

**Ralph creates** `crossplane/configs/crossplane.yaml` — the Configuration package metadata:

```yaml
apiVersion: meta.pkg.crossplane.io/v1
kind: Configuration
metadata:
  name: crossplane-kind-poc
  annotations:
    meta.crossplane.io/maintainer: Platform Engineering Team
    meta.crossplane.io/description: Crossplane Kind PoC Configuration
spec:
  crossplane:
    version: ">=v1.14.0-0"
  dependsOn:
    - provider: xpkg.upbound.io/crossplane-contrib/provider-kubernetes
      version: ">=v0.12.0"
    - provider: xpkg.upbound.io/crossplane-contrib/provider-helm
      version: ">=v0.19.0"
    - provider: xpkg.upbound.io/crossplane-contrib/provider-nop
      version: ">=v0.2.0"
```

**Edge cases:**
- Versions should match those used in Task 1.4 and the setup script

**Acceptance checklist:**

*File checks:*
- [ ] `crossplane/configs/crossplane.yaml` exists
- [ ] Valid YAML
- [ ] `kind: Configuration`
- [ ] `apiVersion: meta.pkg.crossplane.io/v1`
- [ ] `spec.crossplane.version` is set
- [ ] `spec.dependsOn` lists provider-kubernetes, provider-helm, provider-nop
- [ ] All dependency versions match pinned versions elsewhere in the repo

---

### Task 6.2 — Add EnvironmentConfig

**Ralph creates** `crossplane/configs/environment-config.yaml` — a shared environment settings resource.

```yaml
apiVersion: environment.crossplane.io/v1alpha1
kind: EnvironmentConfig
metadata:
  name: crossplane-kind-poc-env
data:
  tags:
    - key: environment
      value: dev
    - key: managed-by
      value: crossplane
  defaultRegion: local
```

**Acceptance checklist:**

*File checks:*
- [ ] `crossplane/configs/environment-config.yaml` exists
- [ ] Valid YAML
- [ ] `kind: EnvironmentConfig`
- [ ] `apiVersion: environment.crossplane.io/v1alpha1`
- [ ] `kubectl apply --dry-run=client` passes

---

## Phase 7 — Documentation & Polish

### Task 7.1 — Finalize README

**Ralph updates** `README.md` to accurately reflect the repo:
- Preserve existing structure (badges, overview, architecture)
- Update all `make` commands to match actual Makefile targets
- Update directory tree to match actual file structure
- Update roadmap checklist (check off completed phases)
- Fix any stale references (e.g., `spec.md` → `docs/spec.md` in links)

**Acceptance checklist:**

*File checks:*
- [ ] README.md is valid markdown (no broken syntax)
- [ ] Every `make` target mentioned in the README actually exists in `Makefile`
- [ ] Every directory mentioned in the tree actually exists
- [ ] Roadmap correctly reflects completed phases
- [ ] All internal links are correct (e.g., `docs/architecture.md` not `architecture.md`)

---

### Task 7.2 — Write `docs/demo.md`

**Ralph creates** `docs/demo.md` with a step-by-step walkthrough:
1. Prerequisites
2. Clone the repo
3. `make cluster-up`
4. `make apply-basic` — show SimpleApp getting created
5. `kubectl get deployment,svc -n my-app` — show expected output
6. `make apply-platform` — show PlatformEnv
7. `kubectl get helmrelease` — show DB
8. Cleanup: `make cluster-down`

Include realistic expected `kubectl` output blocks.

**Edge cases:**
- Commands must be copy-pasteable (no placeholders the user can't resolve)
- Reference `docs/spec.md` and `docs/architecture.md` for deeper reading

**Acceptance checklist:**

*File checks:*
- [ ] `docs/demo.md` exists
- [ ] Every command in demo.md is syntactically valid
- [ ] Every file path referenced in commands actually exists
- [ ] Demo covers setup → simple app → platform env → teardown
- [ ] Links to other docs files are correct

---

### Task 7.3 — Add smoke tests

**Ralph creates** `scripts/test.sh` (and `make test` target) with:
1. Prerequisite check (kind, kubectl, helm, crossplane CLI)
2. Cluster existence check (`kind get clusters`)
3. Crossplane health check (`kubectl get pods -n crossplane-system`)
4. Provider health check (`kubectl get provider`)
5. Simple claim apply → verify → cleanup

**Acceptance checklist:**

*File checks:*
- [ ] `scripts/test.sh` exists and is executable
- [ ] `make test` target exists in `Makefile`
- [ ] `shellcheck scripts/test.sh` passes
- [ ] Tests exit 0 on full pass, non-zero on failure
- [ ] Tests are idempotent (safe to re-run)

---

### Task 7.4 — Final commit and verify

**Ralph** commits all changes with a comprehensive message. Then runs a regression check.

**Acceptance checklist:**

*File checks:*
- [ ] `git status` is clean
- [ ] `git log --oneline -10` shows coherent history
- [ ] No untracked garbage files (`.DS_Store`, `*.tmp`, `.terraform/`, etc.)
- [ ] Whole-repo `kubectl apply --dry-run=client -f crossplane/ -R` passes
- [ ] Whole-repo `kubectl apply --dry-run=client -f argocd/ -R` passes
- [ ] `bash -n scripts/*.sh` passes for all scripts
- [ ] `make -n cluster-up` passes

---

## Dependency graph

Sequential ordering — a task starts only when Verifier confirms all predecessor tasks are complete.

```
Phase 0
 0.1 ─▶ 0.2 ─▶ 0.3
                  │
Phase 1           ▼
 1.1 ─▶ 1.2 ─▶ 1.3 ─▶ 1.4 ─▶ 1.5 ─▶ 1.6
                                          │
Phase 2                                   ▼
 2.1 ─▶ 2.2 ─▶ 2.3 ─▶ 2.4 ─▶ 2.5
                                    │
Phase 3                             ▼
 3.1 ─▶ 3.2 ─▶ 3.3 ─▶ 3.4 ─▶ 3.5
                                    │
Phase 4                             ▼
 4.1 ─▶ 4.2 ─▶ 4.3
                    │
Phase 5             ▼
 5.1 ─▶ 5.2 ─▶ 5.3
                    │
Phase 6             ▼
 6.1 ─▶ 6.2
            │
Phase 7     ▼
 7.1 ─▶ 7.2 ─▶ 7.3 ─▶ 7.4
```

**Fail-fast rule**: If any task fails 3 consecutive loops, do not proceed to the next phase. Report the blocker to the user with:
- What task failed
- What Ralph tried (3 iterations)
- What the Verifier found each time
- Suggested root cause

---

## Cross-cutting verification

These checks can be run at any point and should pass after Phase 1:

| Check | Command |
|---|---|
| All YAML is valid | `find . -name '*.yaml' -exec python3 -c "import yaml; yaml.safe_load(open('{}'))" \;` |
| No stale `.gitkeep` if dirs have content | Empty directories must have `.gitkeep`; dirs with real files should not |
| No absolute host paths in configs | `grep -r '/Users/' cluster/ crossplane/ argocd/` should find nothing |
| K8s manifest dry-run | `kubectl apply --dry-run=client -f crossplane/ -R` |
| Shell scripts valid | `bash -n scripts/*.sh` |
| Makefile syntax | `make -n` (no target = first/default target) |
