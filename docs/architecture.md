# Crossplane Kind PoC - Architecture

## High-Level Overview

This PoC demonstrates **Crossplane** running as a control plane inside a **Kind** cluster. It turns Kubernetes into a universal API for provisioning infrastructure and applications entirely locally.

```mermaid
flowchart TD
    A[Developer / User] -->|kubectl apply| B[Claim<br/>e.g. PlatformEnv]
    B --> C[Crossplane Controller]
    C --> D[Composition]
    D --> E[Provider Kubernetes<br/>+ Provider Helm]
    E --> F[Managed Resources]
    F --> G[Actual K8s Objects<br/>(Deployments, Services, Helm Releases)]
    
    subgraph "Control Plane"
    C
    D
    end
    
    subgraph "Managed Infra"
    G
    end
```

## Core Components

### 1. Cluster Layer
- **Kind**: Multi-node Kubernetes cluster running in Docker containers.
- Resource requests/limits configured for laptop compatibility.
- Extra port mappings for local access (e.g., Ingress).

### 2. Crossplane Control Plane
- Installed via Helm in `crossplane-system` namespace.
- **Providers**:
  - `provider-kubernetes`: Manages any native Kubernetes resource declaratively.
  - `provider-helm`: Deploys and manages Helm charts (databases, observability, etc.).
  - `provider-nop`: For testing and dry-run compositions.

### 3. API & Abstraction Layer

**XRD (Composite Resource Definition)**:
```yaml
apiVersion: apiextensions.crossplane.io/v1
kind: CompositeResourceDefinition
metadata:
  name: xplatformenvs.example.com
spec:
  group: example.com
  names:
    kind: XPlatformEnv
    plural: xplatformenvs
  claimNames:
    kind: PlatformEnv
    plural: platformenvs
  versions:
  - name: v1alpha1
    schema:
      openAPIV3Schema:
        type: object
        properties:
          spec:
            type: object
            properties:
              appImage:
                type: string
              dbType:
                type: string
```

**Composition**:
Implements the XRD by composing multiple managed resources with patches, transforms, and readiness policies.

### 4. User Experience (Claims)

```yaml
apiVersion: example.com/v1alpha1
kind: PlatformEnv
metadata:
  name: my-dev-env
spec:
  appImage: nginx:latest
  dbType: postgres
```

One `kubectl apply` → full environment spins up.

### 5. GitOps Integration (ArgoCD)

```mermaid
graph LR
    GitHub[This Repository] --> ArgoCD[ArgoCD Controller]
    ArgoCD --> Crossplane[Crossplane Resources]
    Crossplane --> K8s[Kind Cluster]
```

ArgoCD continuously reconciles the desired state from Git.

## Key Design Decisions

- **Local-First**: Everything runs without external cloud dependencies.
- **Modular**: Separate directories for XRDs, Compositions, Claims.
- **Reusable**: Composition Functions for complex logic.
- **Observable**: Leverages Crossplane status conditions.
- **Extensible**: Easy to swap providers for real clouds.

## Data Flow

1. User applies Claim
2. Crossplane creates Composite Resource (XR)
3. Composition logic executes
4. Providers create Managed Resources
5. Kubernetes API creates final objects
6. Reconciliation loop maintains desired state

## Future Extension Points

- Replace `provider-kubernetes` with cloud providers
- Add `EnvironmentConfig` for shared settings
- Integrate policy engines (Kyverno)
- Multi-cluster management

**For detailed examples, see the `crossplane/` directory and `docs/demo.md`.**