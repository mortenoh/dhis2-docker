.PHONY: help build run force-run down pull
.DEFAULT_GOAL := help

COMPOSE := docker compose -f compose.yml -f compose.pgadmin.yml

help: ## show this help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

pull: ## pull latest images from Docker Hub
	@echo ">>> Pulling latest images"
	$(COMPOSE) pull

build: ## build images (no cache bust)
	@echo ">>> Building images"
	$(COMPOSE) build

run: ## clean start: wipe volumes + logs, then start the stack
	@echo ">>> Wiping logs"
	rm -rf home/logs/*
	@echo ">>> Tearing down volumes"
	$(COMPOSE) down -v
	@echo ">>> Starting stack"
	$(COMPOSE) up --remove-orphans

force-run: ## wipe volumes + logs, rebuild from scratch, and start
	@echo ">>> Wiping logs"
	rm -rf home/logs/*
	@echo ">>> Tearing down volumes"
	$(COMPOSE) down -v
	@echo ">>> Rebuilding (no cache)"
	$(COMPOSE) build --no-cache
	@echo ">>> Starting stack"
	$(COMPOSE) up --remove-orphans

down: ## stop the stack (keeps volumes)
	@echo ">>> Stopping stack"
	$(COMPOSE) down
