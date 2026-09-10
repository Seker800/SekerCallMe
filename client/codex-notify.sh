#!/usr/bin/env bash

# Optional guaranteed turn-completion fallback. Codex appends its JSON event as
# the final argument; the fallback intentionally sends only a short fixed body.
set -euo pipefail

: "${SEKER_NTFY_URL:?Set SEKER_NTFY_URL, for example http://192.168.1.10:8080}"
: "${SEKER_NTFY_TOPIC:?Set SEKER_NTFY_TOPIC}"
: "${SEKER_NTFY_USER:?Set SEKER_NTFY_USER}"
: "${SEKER_NTFY_PASSWORD:?Set SEKER_NTFY_PASSWORD}"

payload="${1:-{}}"
cwd=""
if command -v jq >/dev/null 2>&1; then
  cwd="$(printf '%s' "$payload" | jq -r '.cwd // empty' 2>/dev/null || true)"
fi

host="$(hostname -s 2>/dev/null || hostname)"
message="Codex on $host finished a turn."
if [[ -n "$cwd" ]]; then
  message="$message Project: $cwd"
fi

curl -fsS \
  -u "${SEKER_NTFY_USER}:${SEKER_NTFY_PASSWORD}" \
  -H "Title: Codex finished on $host" \
  -H 'Priority: 3' \
  -H 'Tags: white_check_mark,computer' \
  -d "$message" \
  "${SEKER_NTFY_URL%/}/${SEKER_NTFY_TOPIC}" >/dev/null
