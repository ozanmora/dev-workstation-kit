SHELL := /bin/bash
.DEFAULT_GOAL := help

help: ## Show commands
	@grep -E '^[a-zA-Z0-9_.-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-24s\033[0m %s\n", $$1, $$2}'

bootstrap: ## Bootstrap stack (env + certs + example + gen + up)
	./bin/devkit bootstrap

gen: ## Generate nginx conf (scans projects/**/.devkit)
	./bin/devkit gen

up: ## Start stack
	./bin/devkit up

down: ## Stop stack
	./bin/devkit down

logs: ## Tail logs
	./bin/devkit logs

ps: ## Show containers
	./bin/devkit ps

reset: ## Reset volumes (DANGEROUS: deletes DB)
	./bin/devkit reset

# ---------------------------
# PHP helpers (via ./bin/devkit)
# ---------------------------

php74: ## Shell into PHP 7.4 container
	./bin/devkit php 74

php82: ## Shell into PHP 8.2 container
	./bin/devkit php 82

php84: ## Shell into PHP 8.4 container
	./bin/devkit php 84

php85: ## Shell into PHP 8.5 container
	./bin/devkit php 85

composer74: ## Run composer in PHP 7.4: make composer74 ARGS="install -d /var/www/projects/app"
	./bin/devkit composer 74 -- $(ARGS)

composer82: ## Run composer in PHP 8.2: make composer82 ARGS="install -d /var/www/projects/app"
	./bin/devkit composer 82 -- $(ARGS)

composer84: ## Run composer in PHP 8.4: make composer84 ARGS="install -d /var/www/projects/app"
	./bin/devkit composer 84 -- $(ARGS)

composer85: ## Run composer in PHP 8.5: make composer85 ARGS="install -d /var/www/projects/app"
	./bin/devkit composer 85 -- $(ARGS)

# ---------------------------
# Database helpers (via ./bin/devkit)
# ---------------------------

mysql: ## Open MySQL client (interactive) as app user
	./bin/devkit mysql

mysql-root: ## Open MySQL client (interactive) as root
	./bin/devkit mysql-root

mysql-dump: ## Dump DB: make mysql-dump OUT=backup.sql
	./bin/devkit mysql-dump $(OUT)

mysql-import: ## Import DB: make mysql-import IN=backup.sql
	./bin/devkit mysql-import $(IN)

# ---------------------------
# Node helpers
# ---------------------------

yarn: ## Run yarn in node container: make yarn ARGS="--version" OR make yarn ARGS="-C projects/app install"
	./bin/devkit yarn $(ARGS)

npm: ## Run npm in node container: make npm ARGS="-- --version" OR make npm ARGS="-- --prefix projects/app run build"
	./bin/devkit npm $(ARGS)


# ---------------------------
# Project init helpers (.devkit)
# Run from DevKit repo root, but note: init writes into the *current working directory*.
# For best results: cd into the project folder and run ../../bin/devkit init ...
# These targets are convenience wrappers if you pass PROJECT=<relative path>.
# ---------------------------

init-php: ## Init a PHP project: make init-php PROJECT=projects/demo DOMAIN=demo.local.test PHP=84 [URLPATH=/portal] [PUBLIC=1|0] [DOCROOT=public]
	@PROJECT="$${PROJECT:-}"; DOMAIN="$${DOMAIN:-}"; \
	if [[ -z "$$PROJECT" || -z "$$DOMAIN" ]]; then echo "Usage: make init-php PROJECT=projects/<name> DOMAIN=<domain> [PHP=84] [URLPATH=/] [PUBLIC=1] [DOCROOT=public]"; exit 1; fi; \
	PHPV="$${PHP:-84}"; URLPATH="$${URLPATH:-/}"; PUBLIC="$${PUBLIC:-1}"; DOCROOT="$${DOCROOT:-}"; \
	cd "$$PROJECT" && \
	if [[ -n "$$DOCROOT" ]]; then ../../bin/devkit init --domain "$$DOMAIN" --type php --php "$$PHPV" --docroot "$$DOCROOT" --url-path "$$URLPATH"; \
	else \
	  if [[ "$$PUBLIC" == "1" ]]; then ../../bin/devkit init --domain "$$DOMAIN" --type php --php "$$PHPV" --public --url-path "$$URLPATH"; \
	  else ../../bin/devkit init --domain "$$DOMAIN" --type php --php "$$PHPV" --docroot . --url-path "$$URLPATH"; fi; \
	fi

init-wp: ## Init a WordPress project: make init-wp PROJECT=projects/wp DOMAIN=wp.local.test PHP=82 [URLPATH=/]
	@PROJECT="$${PROJECT:-}"; DOMAIN="$${DOMAIN:-}"; \
	if [[ -z "$$PROJECT" || -z "$$DOMAIN" ]]; then echo "Usage: make init-wp PROJECT=projects/<name> DOMAIN=<domain> [PHP=82] [URLPATH=/]"; exit 1; fi; \
	PHPV="$${PHP:-82}"; URLPATH="$${URLPATH:-/}"; \
	cd "$$PROJECT" && ../../bin/devkit init --domain "$$DOMAIN" --wordpress --php "$$PHPV" --url-path "$$URLPATH"

init-static: ## Init a static project: make init-static PROJECT=projects/site DOMAIN=site.local.test DOCROOT=build [DEVPORT=5173] [URLPATH=/]
	@PROJECT="$${PROJECT:-}"; DOMAIN="$${DOMAIN:-}"; DOCROOT="$${DOCROOT:-}"; \
	if [[ -z "$$PROJECT" || -z "$$DOMAIN" || -z "$$DOCROOT" ]]; then echo "Usage: make init-static PROJECT=projects/<name> DOMAIN=<domain> DOCROOT=dist|build [DEVPORT=5173] [URLPATH=/]"; exit 1; fi; \
	DEVPORT="$${DEVPORT:-}"; URLPATH="$${URLPATH:-/}"; \
	cd "$$PROJECT" && \
	if [[ -n "$$DEVPORT" ]]; then ../../bin/devkit init --domain "$$DOMAIN" --type static --docroot "$$DOCROOT" --dev-port "$$DEVPORT" --url-path "$$URLPATH"; \
	else ../../bin/devkit init --domain "$$DOMAIN" --type static --docroot "$$DOCROOT" --url-path "$$URLPATH"; fi
