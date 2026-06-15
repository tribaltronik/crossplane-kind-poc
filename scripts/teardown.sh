#!/usr/bin/env bash
set -euo pipefail

# ── Kind cluster ────────────────────────────────────────────────────────────
kind delete cluster --name kind
