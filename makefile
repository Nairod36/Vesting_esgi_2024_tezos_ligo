SHELL := /bin/bash

help:
	@grep -E '^[ a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
	awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'


# ^ use LIGO en var bin if configured, otherwise use docker

compile = ../ligo compile contract  --project-root ./src ./src/$(1) -o ./compiled/$(2) $(3) 
# ^ Compile contracts to Michelson or Micheline

test = ../ligo run test $(project_root) ./test/$(1) --no-warn 
# ^ run given test file	


.PHONY: test compile
compile: ## compile contracts to Michelson
	@mkdir -p compiled
	@$(call compile,Vesting.mligo,Vesting.mligo.json, --michelson-format json)
	@$(call compile,Vesting.mligo,Vesting.tz.json, --michelson-format json)
	

test: ## run tests (SUITE=asset_approve make test)
ifndef SUITE
	@$(call test,Vesting.test.mligo)
else
	@$(call test,$(SUITE).test.mligo)
endif


deploy: deploy_deps deploy.js ## deploy exo_2

deploy.js:
	@echo "Running deploy script\n"
	@cd deploy && npm i && npm run deploy_exo2

deploy_deps:
	@echo "Installing deploy script dependencies"
	@cd deploy && npm install
	@echo ""