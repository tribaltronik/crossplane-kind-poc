#!/usr/bin/env bash
set -euo pipefail

ARGOCD_VERSION="v2.12.0"
NAMESPACE="argocd"

echo "Creating namespace ${NAMESPACE}..."
kubectl create namespace ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

echo "Installing ArgoCD ${ARGOCD_VERSION}..."
kubectl apply -n ${NAMESPACE} -f "https://raw.githubusercontent.com/argoproj/argo-cd/${ARGOCD_VERSION}/manifests/install.yaml"
