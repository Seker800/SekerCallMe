#!/usr/bin/env bash

set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
port="${SEKER_QWEN_TTS_PORT:-8785}"
startup_timeout="${SEKER_QWEN_TTS_STARTUP_TIMEOUT:-30}"
health_url="http://127.0.0.1:${port}/v1/health"
runtime_dir="${SEKER_RUNTIME_DIR:-$root/runtime}"
activity_file="$runtime_dir/qwen-tts.last-used"
lock_path="$runtime_dir/qwen-tts.wake.lock"
label="com.seker.callme.qwen-tts"
lock_owned=0

mark_used() {
  mkdir -p "$runtime_dir"
  touch "$activity_file"
}

release_lock() {
  if ((lock_owned)); then
    if [[ "$(readlink "$lock_path" 2>/dev/null || true)" == "$$" ]]; then
      rm -f "$lock_path"
    fi
  fi
}
trap release_lock EXIT

healthy() {
  curl -fsS --connect-timeout 1 --max-time 1 "$health_url" >/dev/null 2>&1
}

mark_used
healthy && exit 0

deadline=$((SECONDS + startup_timeout))
while ! ln -s "$$" "$lock_path" 2>/dev/null; do
  healthy && exit 0
  lock_owner="$(readlink "$lock_path" 2>/dev/null || true)"
  if [[ "$lock_owner" =~ ^[0-9]+$ ]] && ! kill -0 "$lock_owner" 2>/dev/null; then
    rm -f "$lock_path"
    continue
  fi
  ((SECONDS < deadline)) || exit 1
  sleep 0.1
done
lock_owned=1

healthy && exit 0
launchctl kickstart -k "gui/$(id -u)/${label}" >/dev/null 2>&1 || exit 1

while ((SECONDS < deadline)); do
  if healthy; then
    mark_used
    exit 0
  fi
  sleep 0.25
done

exit 1
