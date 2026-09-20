#!/usr/bin/env bash

# Optional guaranteed turn-completion fallback. Codex appends its JSON event as
# the final argument. The global agent policy keeps the first line concise and
# safe to speak, so the hook can reuse it as the audible outcome.
set -euo pipefail

: "${SEKER_NTFY_URL:?Set SEKER_NTFY_URL, for example http://192.168.1.10:8080}"
: "${SEKER_NTFY_TOPIC:?Set SEKER_NTFY_TOPIC}"
: "${SEKER_NTFY_USER:?Set SEKER_NTFY_USER}"
: "${SEKER_NTFY_PASSWORD:?Set SEKER_NTFY_PASSWORD}"
export -n SEKER_NTFY_URL SEKER_NTFY_TOPIC SEKER_NTFY_USER SEKER_NTFY_PASSWORD

curl_config_escape() {
  local value="$1"
  [[ "$value" != *$'\n'* && "$value" != *$'\r'* ]] || return 1
  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  printf '%s' "$value"
}

curl_basic_config() {
  local username password url
  username="$(curl_config_escape "$SEKER_NTFY_USER")"
  password="$(curl_config_escape "$SEKER_NTFY_PASSWORD")"
  url="$(curl_config_escape "${SEKER_NTFY_URL%/}/${SEKER_NTFY_TOPIC}")"
  printf 'user = "%s:%s"\nurl = "%s"\n' "$username" "$password" "$url"
}

payload="${1:-{}}"
message=""
if command -v jq >/dev/null 2>&1; then
  event_type="$(printf '%s' "$payload" | jq -r '.type // empty' 2>/dev/null || true)"
  if [[ -n "$event_type" && "$event_type" != "agent-turn-complete" ]]; then
    exit 0
  fi

  message="$(
    printf '%s' "$payload" |
      jq -r '.["last-assistant-message"] // empty | tostring' 2>/dev/null |
      awk 'NF { sub(/^[[:space:]#>*-]+/, ""); print; exit }' |
      cut -c1-300 || true
  )"
fi

if [[ -z "$message" ]]; then
  message='Codex 已完成当前任务，请查看最终结果。'
fi

curl -fsS \
  --config <(curl_basic_config) \
  -H 'Title: Codex 任务结束' \
  -H 'Priority: 3' \
  -H 'Tags: white_check_mark,computer' \
  -d "$message" >/dev/null
