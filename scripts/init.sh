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

ntfy_health_url="http://${LAN_HOST}:${NTFY_PORT}/v1/health"
for _ in $(seq 1 30); do
  if curl -fsS "$ntfy_health_url" >/dev/null; then
    break
  fi
  sleep 1
done
curl -fsS "$ntfy_health_url" >/dev/null

managed_user_file="$root/runtime/managed-ntfy-user"
mkdir -p "$root/runtime"
record_managed_user() {
  printf '%s\n' "$NTFY_USER" >"${managed_user_file}.tmp"
  chmod 600 "${managed_user_file}.tmp"
  mv "${managed_user_file}.tmp" "$managed_user_file"
}
if [[ -f "$managed_user_file" ]]; then
  previous_user="$(<"$managed_user_file")"
  if [[ "$previous_user" =~ ^[A-Za-z0-9._-]+$ && "$previous_user" != "$NTFY_USER" ]]; then
    if ! ntfy_users="$(docker compose exec -T ntfy ntfy user list 2>/dev/null)"; then
      echo 'Could not inspect the previously managed ntfy user; its marker was preserved.' >&2
      exit 1
    fi
    if grep -Fq "user ${previous_user} (" <<<"$ntfy_users" && \
      ! docker compose exec -T ntfy ntfy user remove "$previous_user" >/dev/null 2>&1; then
      echo 'Could not remove the previously managed ntfy user; its marker was preserved.' >&2
      exit 1
    fi
    record_managed_user
  fi
fi

export NTFY_PASSWORD NTFY_USER NTFY_TOPIC
docker compose exec -T -e NTFY_PASSWORD -e NTFY_USER ntfy \
  sh -eu -c 'ntfy user add --ignore-exists "$NTFY_USER"' >/dev/null
docker compose exec -T -e NTFY_PASSWORD -e NTFY_USER ntfy \
  sh -eu -c 'ntfy user change-pass "$NTFY_USER"' >/dev/null
docker compose exec -T -e NTFY_USER ntfy \
  sh -eu -c 'ntfy access --reset "$NTFY_USER"' >/dev/null
docker compose exec -T -e NTFY_USER -e NTFY_TOPIC ntfy \
  sh -eu -c 'ntfy access "$NTFY_USER" "$NTFY_TOPIC" rw' >/dev/null
export -n NTFY_PASSWORD NTFY_USER NTFY_TOPIC
record_managed_user

docker compose up -d
"$root/scripts/generate-client-config.sh" >/dev/null
"$root/scripts/smoke-test.sh"

echo
echo "Let Agent Speak is ready."
echo "ntfy: configured on the private LAN (topic omitted)"
echo "MCP:  gateway configured (address omitted)"
echo "Client configuration: $root/runtime/codex-config.toml"
