.PHONY: help pull build run run-force run-full run-force-full down clean
.DEFAULT_GOAL := help

COMPOSE      := docker compose -f compose.yml -f compose.pgadmin.yml
COMPOSE_FULL := docker compose -f compose.yml -f compose.pgadmin.yml -f compose.superset.yml

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

run-force: ## wipe volumes + logs, rebuild images from scratch, and start
	@echo ">>> Wiping logs"
	rm -rf home/logs/*
	@echo ">>> Tearing down volumes"
	$(COMPOSE) down -v
	@echo ">>> Rebuilding (no cache)"
	$(COMPOSE) build --no-cache
	@echo ">>> Starting stack"
	$(COMPOSE) up --remove-orphans

run-full: ## clean start of the full stack including Superset BI (UI on :8088)
	@echo ">>> Wiping logs"
	rm -rf home/logs/*
	@echo ">>> Tearing down volumes"
	$(COMPOSE_FULL) down -v
	@echo ">>> Starting full stack (with Superset)"
	$(COMPOSE_FULL) up --remove-orphans

run-force-full: ## wipe volumes + logs, rebuild images from scratch, and start full stack
	@echo ">>> Wiping logs"
	rm -rf home/logs/*
	@echo ">>> Tearing down volumes"
	$(COMPOSE_FULL) down -v
	@echo ">>> Rebuilding (no cache)"
	$(COMPOSE_FULL) build --no-cache
	@echo ">>> Starting full stack (with Superset)"
	$(COMPOSE_FULL) up --remove-orphans

down: ## stop the stack (keeps volumes; covers both plain and full)
	@echo ">>> Stopping stack"
	$(COMPOSE_FULL) down

clean: ## nuke everything: stop containers, remove volumes, wipe logs and runtime data
	@echo ">>> Stopping containers and removing volumes"
	$(COMPOSE_FULL) down -v --remove-orphans
	@echo ">>> Wiping host runtime data (logs, glowroot)"
	rm -rf home/logs/* home/glowroot
