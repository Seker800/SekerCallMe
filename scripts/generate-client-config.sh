#!/usr/bin/env bash

set -euo pipefail
umask 077

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib.sh
source "$root/scripts/lib.sh"
load_env

mkdir -p "$root/runtime"
config="$root/runtime/codex-config.toml"

printf '%s\n' \
  '[mcp_servers.seker_call_me]' \
  "url = \"http://${LAN_HOST}:${MCP_PORT}/mcp\"" \
  'required = false' \
  'enabled_tools = ["ntfy_publish_message"]' \
  'default_tools_approval_mode = "approve"' \
  "http_headers = { Authorization = \"Bearer ${MCP_ACCESS_TOKEN}\" }" \
  > "$config"

chmod 600 "$config"
echo "$config"
