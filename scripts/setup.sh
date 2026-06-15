#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

# ── Prerequisites ──────────────────────────────────────────────────────────────
for cmd in kind kubectl helm crossplane; do
    if ! command -v "$cmd" &>/dev/null; then
        error "Missing prerequisite: '$cmd' is not installed. Install it and try again."
    fi
done
info "All prerequisites found."

# ── Kind cluster ───────────────────────────────────────────────────────────────
CLUSTER_NAME="kind"
if kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
    warn "Kind cluster '${CLUSTER_NAME}' already exists — skipping creation."
else
    info "Creating Kind cluster '${CLUSTER_NAME}'..."
    kind create cluster --config cluster/kind-config.yaml --wait 5m
fi

info "Verifying cluster connection..."
kubectl cluster-info --context "kind-${CLUSTER_NAME}"

# ── Crossplane install ─────────────────────────────────────────────────────────
info "Adding Crossplane Helm repository..."
helm repo add crossplane-stable https://charts.crossplane.io/stable
helm repo update

info "Installing Crossplane via Helm (upgrade --install)..."
helm upgrade --install crossplane crossplane-stable/crossplane \
    --namespace crossplane-system \
    --create-namespace \
    --wait \
    --version 1.17.0

info "Waiting for Crossplane Deployment to be available..."
kubectl wait --for=condition=available deployment/crossplane \
    --namespace crossplane-system \
    --timeout=5m

# ── Crossplane providers ───────────────────────────────────────────────────────
if [ -d crossplane/providers ]; then
    shopt -s nullglob
    provider_files=(crossplane/providers/*.yaml)
    shopt -u nullglob
    if [ ${#provider_files[@]} -gt 0 ]; then
        info "Installing Crossplane providers (phase 1: Provider resources, ignoring ProviderConfig errors)..."
        # First pass: create Provider packages (ProviderConfig CRDs don't exist yet)
        set +e
        for f in "${provider_files[@]}"; do
            kubectl apply -f "$f" 2>/dev/null || true
        done
        set -e

        info "Waiting for providers to become healthy..."
        kubectl wait --for=condition=healthy provider.pkg.crossplane.io --all --timeout=5m

        info "Installing Crossplane providers (phase 2: ProviderConfigs)..."
        # Second pass: now CRDs exist, so ProviderConfigs will apply
        for f in "${provider_files[@]}"; do
            kubectl apply -f "$f"
        done
    else
        warn "No YAML manifests found in crossplane/providers/ — skipping provider installation."
    fi
else
    warn "Directory crossplane/providers/ does not exist — skipping provider installation."
fi

# ── Summary ────────────────────────────────────────────────────────────────────
echo ""
info "========== Setup Complete =========="
echo "  Cluster:           kind-${CLUSTER_NAME}"
crossplane_replicas=$(kubectl get deployment crossplane \
    -n crossplane-system \
    -o jsonpath='{.status.availableReplicas}' 2>/dev/null || echo "N/A")
echo "  Crossplane:        ${crossplane_replicas} replicas available"
if kubectl get provider.pkg.crossplane.io &>/dev/null; then
    echo "  Providers:"
    kubectl get provider.pkg.crossplane.io \
        -o custom-columns=NAME:.metadata.name,HEALTHY:.status.conditionedStatus.conditions[0].status,AGE:.metadata.creationTimestamp
fi
echo "====================================="
