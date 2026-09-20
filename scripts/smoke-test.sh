#!/usr/bin/env bash

set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib.sh
source "$root/scripts/lib.sh"
require_command curl
require_command jq
load_env

ntfy_url="http://${LAN_HOST}:${NTFY_PORT}"
mcp_url="http://${LAN_HOST}:${MCP_PORT}/mcp"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

curl -fsS "$ntfy_url/v1/health" >/dev/null

ntfy_unauthorized_status="$(curl -sS -o /dev/null -w '%{http_code}' \
  --config <(printf 'url = "%s"\n' \
    "$(curl_config_escape "$ntfy_url/$NTFY_TOPIC/json?poll=1")"))"
if [[ "$ntfy_unauthorized_status" != "401" && "$ntfy_unauthorized_status" != "403" ]]; then
  echo "Expected anonymous ntfy request to be denied, got $ntfy_unauthorized_status" >&2
  exit 1
fi

other_topic_status="$(curl -sS -o /dev/null -w '%{http_code}' \
  --config <(curl_basic_config \
    "$NTFY_USER" \
    "$NTFY_PASSWORD" \
    "$ntfy_url/not-allowed/json?poll=1"))"
if [[ "$other_topic_status" != "401" && "$other_topic_status" != "403" ]]; then
  echo "Expected the least-privilege ntfy user to be denied on another topic, got $other_topic_status" >&2
  exit 1
fi

unauthorized_status="$(curl -sS -o /dev/null -w '%{http_code}' \
  -X POST "$mcp_url" \
  -H 'Content-Type: application/json' \
  -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-06-18","capabilities":{},"clientInfo":{"name":"seker-call-me-smoke","version":"1.0"}}}')"

if [[ "$unauthorized_status" != "401" ]]; then
  echo "Expected unauthenticated MCP request to return 401, got $unauthorized_status" >&2
  exit 1
fi

common_headers=(
  -H 'Content-Type: application/json'
  -H 'Accept: application/json, text/event-stream'
)
delivery_marker="Let Agent Speak smoke $(date +%s)-$$-${RANDOM}"

curl -fsS -D "$tmp_dir/initialize.headers" -o "$tmp_dir/initialize.body" \
  -X POST "$mcp_url" \
  --config <(curl_bearer_config "$MCP_ACCESS_TOKEN") \
  "${common_headers[@]}" \
  -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-06-18","capabilities":{},"clientInfo":{"name":"seker-call-me-smoke","version":"1.0"}}}'

session_id="$(sed -n 's/^[Mm][Cc][Pp]-[Ss]ession-[Ii][Dd]:[[:space:]]*//p' \
  "$tmp_dir/initialize.headers" | tr -d '\r')"
if [[ -z "$session_id" ]]; then
  echo 'MCP initialize did not return a session ID.' >&2
  exit 1
fi

curl -fsS -o /dev/null \
  -X POST "$mcp_url" \
  --config <(curl_bearer_config "$MCP_ACCESS_TOKEN") \
  "${common_headers[@]}" \
  -H "Mcp-Session-Id: $session_id" \
  -d '{"jsonrpc":"2.0","method":"notifications/initialized","params":{}}'

curl -fsS -o "$tmp_dir/tools.body" \
  -X POST "$mcp_url" \
  --config <(curl_bearer_config "$MCP_ACCESS_TOKEN") \
  "${common_headers[@]}" \
  -H "Mcp-Session-Id: $session_id" \
  -d '{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}'
if ! grep -q 'ntfy_publish_message' "$tmp_dir/tools.body"; then
  echo 'MCP tool list does not contain ntfy_publish_message.' >&2
  exit 1
fi

curl -fsS -o "$tmp_dir/call.body" \
  -X POST "$mcp_url" \
  --config <(curl_bearer_config "$MCP_ACCESS_TOKEN") \
  "${common_headers[@]}" \
  -H "Mcp-Session-Id: $session_id" \
  -d "$(jq -cn --arg message "$delivery_marker" '{jsonrpc:"2.0",id:3,method:"tools/call",params:{name:"ntfy_publish_message",arguments:{title:"Let Agent Speak smoke test",message:$message,priority:3,tags:["white_check_mark"]}}}')"
if ! grep -Fq "$delivery_marker" "$tmp_dir/call.body"; then
  echo 'MCP notification call did not report success.' >&2
  exit 1
fi

if ! curl -fsS \
  --config <(curl_basic_config \
    "$NTFY_USER" \
    "$NTFY_PASSWORD" \
    "$ntfy_url/$NTFY_TOPIC/json?poll=1&since=10m") | \
  jq -e --arg message "$delivery_marker" \
    'select(.event == "message" and .message == $message)' >/dev/null; then
  echo 'The notification published by this smoke-test run was not found in ntfy.' >&2
  exit 1
fi

echo "Smoke test passed: health, MCP authentication, handshake, tool call, and readback."
