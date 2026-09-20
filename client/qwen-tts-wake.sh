#!/usr/bin/env bash

set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
port="${SEKER_QWEN_TTS_PORT:-8785}"
startup_timeout="${SEKER_QWEN_TTS_STARTUP_TIMEOUT:-30}"
health_url="http://127.0.0.1:${port}/v1/health"
activity_file="$root/runtime/qwen-tts.last-used"
label="com.seker.callme.qwen-tts"

mark_used() {
  mkdir -p "$root/runtime"
  touch "$activity_file"
}

healthy() {
  curl -fsS --connect-timeout 1 --max-time 1 "$health_url" >/dev/null 2>&1
}

mark_used
healthy && exit 0

launchctl kickstart "gui/$(id -u)/${label}" >/dev/null 2>&1 || exit 1

deadline=$((SECONDS + startup_timeout))
while ((SECONDS < deadline)); do
  if healthy; then
    mark_used
    exit 0
  fi
  sleep 0.25
done

exit 1
