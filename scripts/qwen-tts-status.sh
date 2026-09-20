#!/usr/bin/env bash

set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib.sh
source "$root/scripts/lib.sh"

require_command curl
require_command launchctl
load_env

port="${SEKER_QWEN_TTS_PORT:-8785}"
launchctl print "gui/$(id -u)/com.seker.callme.qwen-tts" >/dev/null
if /usr/bin/curl -fsS --connect-timeout 1 --max-time 1 "http://127.0.0.1:${port}/v1/health" >/dev/null 2>&1; then
  printf 'Qwen3-TTS is running on the local-only speech endpoint.\n'
else
  printf 'Qwen3-TTS is installed and sleeping; the next message will wake it.\n'
fi
