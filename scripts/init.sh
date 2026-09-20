#!/usr/bin/env bash

set -euo pipefail
umask 077

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib.sh
source "$root/scripts/lib.sh"

require_command docker
require_command curl
require_command openssl

if [[ ! -f "$root/.env" ]]; then
  lan_host="$(detect_lan_host)"
  if [[ -z "$lan_host" ]]; then
    echo "Could not detect a LAN address. Copy .env.example to .env and set LAN_HOST." >&2
    exit 1
  fi

  mcp_token="$(openssl rand -hex 32)"
  ntfy_password="$(openssl rand -base64 24 | tr -d '\n')"
  ntfy_topic="codex-$(openssl rand -hex 12)"

  printf '%s\n' \
    "LAN_HOST=$lan_host" \
    "MCP_PORT=3010" \
    "NTFY_PORT=8080" \
    "MCP_ACCESS_TOKEN=$mcp_token" \
    "NTFY_USER=codex" \
    "NTFY_PASSWORD=$ntfy_password" \
    "NTFY_TOPIC=$ntfy_topic" \
    "SEKER_VOICE=Tingting" \
    "SEKER_VOICE_RATE=170" > "$root/.env"
fi

load_env

cd "$root"
docker compose up -d ntfy

for _ in $(seq 1 30); do
  if curl -fsS "http://127.0.0.1:${NTFY_PORT}/v1/health" >/dev/null; then
    break
  fi
  sleep 1
done
curl -fsS "http://127.0.0.1:${NTFY_PORT}/v1/health" >/dev/null

docker compose exec -T -e NTFY_PASSWORD="$NTFY_PASSWORD" ntfy \
  ntfy user add --ignore-exists "$NTFY_USER" >/dev/null
docker compose exec -T -e NTFY_PASSWORD="$NTFY_PASSWORD" ntfy \
  ntfy user change-pass "$NTFY_USER" >/dev/null
docker compose exec -T ntfy ntfy access "$NTFY_USER" "$NTFY_TOPIC" rw >/dev/null

docker compose up -d
"$root/scripts/generate-client-config.sh" >/dev/null
"$root/scripts/smoke-test.sh"

echo
echo "Let Agent Speak is ready."
echo "ntfy: http://${LAN_HOST}:${NTFY_PORT}/${NTFY_TOPIC}"
echo "MCP:  http://${LAN_HOST}:${MCP_PORT}/mcp"
echo "Client configuration: $root/runtime/codex-config.toml"
