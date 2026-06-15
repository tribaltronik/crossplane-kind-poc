# AGENTS.md — crossplane-kind-poc

## State

Design/planning phase. Most infra code (`crossplane/`, `cluster/`, `scripts/`, `argocd/`, `Makefile`) has not been written yet. Tracked files: `README.md`, `docs/*.md`.

## Implementation plan

`docs/ralph-loop-plan.md` — atomic tasks with acceptance checklists, structured for two-agent iterative execution (Ralph implements, Verifier checks, loop until pass).

`docs/plan.md` — original 7-phase sequential build plan (Phase 0–7).

## Existing docs (preserve, do not delete)

- `docs/spec.md` — project specification and scope
- `docs/architecture.md` — architecture overview with Mermaid diagrams
- `docs/plan.md` — implementation roadmap
- `docs/ralph-loop-plan.md` — agentic execution plan (this session)

## Key commands (targets)

Designed in README, to be added via `Makefile` in Phase 1:

| Command | What it does |
|---|---|
| `make cluster-up` | Kind cluster + Crossplane install |
| `make cluster-down` | Teardown |
| `make apply-basic` | Apply SimpleApp claim |
| `make apply-platform` | Apply PlatformEnv claim |
| `make render` | `crossplane beta render` local validation |

## Fast feedback

`crossplane beta render` — recommended inner loop for Composition development (no cluster needed, just the CLI).

## Conventions

- Work phases from `docs/plan.md` sequentially
- After each phase: update README, commit, test full flow
- Pin provider/Helm chart versions — never use `:latest`
- All K8s manifests must pass `kubectl apply --dry-run=client`
- Shell scripts must pass `shellcheck` and use `set -euo pipefail`
