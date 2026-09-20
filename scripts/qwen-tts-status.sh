#!/usr/bin/env bash

set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib.sh
source "$root/scripts/lib.sh"

require_command curl
require_command launchctl
load_env

port="${SEKER_QWEN_TTS_PORT:-8785}"
revision="e391ec5467b0218eeb175f4888ad65b259d1e7c7"
install_dir="$root/runtime/qwen3-tts/$revision"
binary="$install_dir/source/qwen_tts"
model_dir="$install_dir/model"
activity_file="$root/runtime/qwen-tts.last-used"
busy_window=$((${SEKER_QWEN_TTS_TIMEOUT:-30} + ${SEKER_QWEN_TTS_STARTUP_TIMEOUT:-30}))
job_status="$(launchctl print "gui/$(id -u)/com.seker.callme.qwen-tts" 2>&1)" || {
  echo 'Qwen3-TTS LaunchAgent is not installed.' >&2
  exit 1
}
[[ -x "$binary" ]] && qwen_model_complete "$model_dir" || {
  echo 'Qwen3-TTS installation is incomplete. Run: make voice-ai-install' >&2
  exit 1
}
if /usr/bin/curl -fsS --connect-timeout 1 --max-time 1 "http://127.0.0.1:${port}/v1/health" >/dev/null 2>&1; then
  printf 'Qwen3-TTS is running on the local-only speech endpoint.\n'
elif grep -q 'state = running' <<<"$job_status"; then
  last_used="$(stat -f '%m' "$activity_file" 2>/dev/null || printf 0)"
  now="$(date +%s)"
  if ((last_used > 0 && now - last_used <= busy_window)); then
    printf 'Qwen3-TTS is starting or processing a local speech request.\n'
  else
    echo 'Qwen3-TTS is running but its health endpoint is unavailable.' >&2
    exit 1
  fi
elif [[ "$(sed -n 's/^[[:space:]]*last exit code = //p' <<<"$job_status" | tail -1)" =~ ^[1-9][0-9]*$ ]]; then
  echo 'Qwen3-TTS exited with an error. Run: make voice-ai-install' >&2
  exit 1
else
  printf 'Qwen3-TTS is installed and sleeping; the next message will wake it.\n'
fi
