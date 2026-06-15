# Composition Functions

Crossplane Composition Functions are pluggable units of logic that transform composed resources during composition rendering. They replace or complement the older `spec.resources` approach with a `spec.pipeline` of function steps.

## Functions in use

| Function | Package | Purpose |
|---|---|---|
| `function-patch-and-transform` | `xpkg.upbound.io/upbound/function-patch-and-transform` | Patch and transform composed resources (replaces the old `spec.resources` approach) |
| `function-go-templating` | `xpkg.upbound.io/crossplane-contrib/function-go-templating` | Render resources using Go templates with access to the observed composite and composed resource state |

## Pipeline architecture

Compositions using `mode: Pipeline` define an ordered list of function steps. Each step:

1. Receives the observed state (composite + composed resources)
2. Processes it via the referenced function
3. Passes the result to the next step in the pipeline

```
observed.composite ──▶ Step 1: go-templating ──▶ Step 2: patch-and-transform ──▶ desired.composed
```

## Adding a custom function

1. **Deploy the Function resource** — create a `kind: Function` manifest in this directory (see `go-templating.yaml` for an example) and apply it to the cluster.
2. **Reference it in a Composition** — add a new step to the `spec.pipeline` of any Composition, using the function name in `functionRef.name`.
3. **Provide input** — each function step can have an `input` block with function-specific configuration.

## Developing a custom function

Crossplane provides official SDKs for building custom functions:

- **Go SDK**: https://github.com/crossplane/function-sdk-go
- **Python SDK**: https://github.com/crossplane/function-sdk-python
- **Templates**: https://github.com/crossplane/function-template-go

A custom function is packaged as a Crossplane package (`xpkg`) and pushed to a registry. The `kind: Function` resource points to the published package.

## Function resources

Apply all functions in this directory:

```bash
kubectl apply -f crossplane/functions/
```
