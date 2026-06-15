.PHONY: cluster-up cluster-down status render render-simple render-platform apply-basic apply-platform help

cluster-up: ## Create Kind cluster and install Crossplane
	./scripts/setup.sh

cluster-down: ## Tear down Kind cluster
	./scripts/teardown.sh

status: ## Show Crossplane status (providers, providerconfigs)
	kubectl get provider,providerconfig

render: ## Render a Composition locally (requires Docker)
	crossplane composition render crossplane/xrs/my-simple-app-xr.yaml \
		crossplane/compositions/xsimpleapp.yaml \
		crossplane/functions/patch-and-transform.yaml \
		--xrd=crossplane/xrds/xsimpleapp.yaml

render-simple: ## Render the SimpleApp Composition
	crossplane composition render crossplane/xrs/my-simple-app-xr.yaml \
		crossplane/compositions/xsimpleapp.yaml \
		crossplane/functions/patch-and-transform.yaml \
		--xrd=crossplane/xrds/xsimpleapp.yaml

render-platform: ## Render the PlatformEnv Composition
	crossplane composition render crossplane/xrs/my-dev-env-xr.yaml \
		crossplane/compositions/xplatformenv.yaml \
		crossplane/functions/patch-and-transform.yaml \
		--xrd=crossplane/xrds/xplatformenv.yaml

apply-basic: ## Apply the SimpleApp claim (Phase 2)
	kubectl apply -f crossplane/claims/simple-app.yaml

apply-platform: ## Apply the PlatformEnv claim (Phase 3)
	kubectl apply -f crossplane/claims/platform-env.yaml

help: ## Show this help message
	@echo "Usage: make <target>"
	@echo ""
	@echo "Targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-20s %s\n", $$1, $$2}'
