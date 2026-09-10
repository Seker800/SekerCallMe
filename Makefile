.PHONY: init up down logs status check smoke client-config voice-install voice-uninstall voice-status voice-test

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

voice-install:
	./scripts/install-voice-subscriber.sh

voice-uninstall:
	./scripts/uninstall-voice-subscriber.sh

voice-status:
	launchctl print gui/$$(id -u)/com.seker.callme.voice

voice-test:
	./scripts/publish-voice-test.sh
