IMAGE ?= nginx-portainer
TAG ?= local
COMPOSE ?= docker compose

.PHONY: help build up rebuild down restart logs ps pull push

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

build: ## Build + tag the nginx image once (compose then reuses the image)
	$(COMPOSE) build nginx

up: ## Start services
	$(COMPOSE) up -d

rebuild: ## Force-rebuild nginx and restart everything
	$(COMPOSE) up -d --build

down: ## Stop and remove containers
	$(COMPOSE) down

restart: ## Restart containers
	$(COMPOSE) restart

logs: ## Tail logs
	$(COMPOSE) logs -f --tail=100

ps: ## Show running services
	$(COMPOSE) ps

pull: ## Pull prebuilt images
	$(COMPOSE) pull

push: ## Push nginx image to a registry (override IMAGE/TAG if needed)
	docker push $(IMAGE):$(TAG)