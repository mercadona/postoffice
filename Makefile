#!/usr/bin/make -f

PROJECT_NAME := 'Postoffice'

.DEFAULT_GOAL := help

.PHONY: test build
.PHONY: env-start env-stop env-restart env-recreate docker-cleanup bash
.PHONY: view-logs help

POSTOFFICE_ROOT_FOLDER := $(shell pwd)
DOCKER_COMPOSE_FILE := $(POSTOFFICE_ROOT_FOLDER)/docker/docker-compose.yml
POSTOFFICE_SERVICE := app
DOCKER_PROJECT_NAME := postoffice
DOCKER_COMPOSE_COMMAND := docker-compose -p $(DOCKER_PROJECT_NAME) -f $(DOCKER_COMPOSE_FILE)

ifeq ($(DOCKER_NAMESPACE),)
export DOCKER_NAMESPACE := mercadona
export DOCKER_COMPOSE_COMMAND := docker-compose -p $(DOCKER_PROJECT_NAME) -f $(DOCKER_COMPOSE_FILE)
endif

ifeq ($(DOCKER_IMAGE_NAME),)
export DOCKER_IMAGE_NAME := postoffce
endif

ifeq ($(DOCKER_IMAGE_TAG),)
export DOCKER_IMAGE_TAG := latest
endif

ifeq ($(DOCKER_BRANCH_NAME),)
export DOCKER_BRANCH_NAME := local
endif


test: ## Run test suite in project's main container
	$(DOCKER_COMPOSE_COMMAND) exec -T $(POSTOFFICE_SERVICE) mix test

build: ## Build project image
	$(DOCKER_COMPOSE_COMMAND) build --no-cache --pull

env-start: ## Start project containers defined in docker-compose
	$(DOCKER_COMPOSE_COMMAND) up -d db
	$(DOCKER_COMPOSE_COMMAND) up migrations
	$(DOCKER_COMPOSE_COMMAND) up -d app

env-stop: ## Stop project containers defined in docker-compose
	$(DOCKER_COMPOSE_COMMAND) stop

env-restart: env-stop env-start

env-destroy: ## Destroy all project containers
	$(DOCKER_COMPOSE_COMMAND) down -v --rmi all --remove-orphans

env-recreate: build env-start ## Force building project image and start all containers again

env-reset: destroy-containers env-start ## Destroy project containers and start them again

destroy-containers: ## Destroy project containers
	$(DOCKER_COMPOSE_COMMAND) down -v

docker-cleanup: ## Purge all Docker images in the system
	$(DOCKER_COMPOSE_COMMAND) down -v
	docker system prune -f

bash: ## Open a bash shell in project's main container
	$(DOCKER_COMPOSE_COMMAND) exec $(POSTOFFICE_SERVICE) bash

view-logs: ## Display interactive logs of all project containers
	$(DOCKER_COMPOSE_COMMAND) logs -f $(service)

help: ## Display this help text
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
