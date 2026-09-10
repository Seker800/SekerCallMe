#!/usr/bin/env bash

set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib.sh
source "$root/scripts/lib.sh"
require_command curl
load_env

/usr/bin/curl -fsS \
  -u "${NTFY_USER}:${NTFY_PASSWORD}" \
  -H 'Title: Codex 语音测试' \
  -H 'Priority: 4' \
  -d '现在我真的会通过 MCP 消息喊你了。' \
  "http://${LAN_HOST}:${NTFY_PORT}/${NTFY_TOPIC}" >/dev/null

echo 'Voice test notification published.'
