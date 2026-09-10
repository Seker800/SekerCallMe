.PHONY: init up down logs status check smoke client-config

init:
	./scripts/init.sh

up:
	docker compose up -d

down:
	docker compose down

logs:
	docker compose logs -f

status:
	docker compose ps

check:
	./scripts/check.sh

smoke:
	./scripts/smoke-test.sh

client-config:
	./scripts/generate-client-config.sh
