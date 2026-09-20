#!/usr/bin/env bash

set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../scripts/lib.sh
source "$root/scripts/lib.sh"
load_env_private

qwen_revision="e391ec5467b0218eeb175f4888ad65b259d1e7c7"
install_dir="$root/runtime/qwen3-tts/$qwen_revision"
binary="$install_dir/source/qwen_tts"
model_dir="$install_dir/model"
port="${SEKER_QWEN_TTS_PORT:-8785}"
threads="${SEKER_QWEN_TTS_THREADS:-8}"
idle_seconds="${SEKER_QWEN_TTS_IDLE_SECONDS:-1200}"
activity_file="$root/runtime/qwen-tts.last-used"

[[ -x "$binary" ]] || {
  echo 'Qwen3-TTS binary is missing. Run: make voice-ai-install' >&2
  exit 1
}
qwen_model_complete "$model_dir" || {
  echo 'Qwen3-TTS model is missing. Run: make voice-ai-install' >&2
  exit 1
}

mkdir -p "$root/runtime"
touch "$activity_file"

/usr/bin/env -i \
  PATH=/usr/bin:/bin:/usr/sbin:/sbin \
  LANG="${LANG:-en_US.UTF-8}" \
  "$binary" \
  -d "$model_dir" \
  --int8 \
  -j "$threads" \
  --max-request-seconds 30 \
  --max-text-chars 600 \
  --serve "$port" &
server_pid=$!

stop_server() {
  trap - INT TERM
  if kill -0 "$server_pid" >/dev/null 2>&1; then
    kill -TERM "$server_pid" >/dev/null 2>&1 || true
    wait "$server_pid" || true
  fi
  exit 0
}
trap stop_server INT TERM

while kill -0 "$server_pid" >/dev/null 2>&1; do
  sleep 5
  last_used="$(stat -f '%m' "$activity_file" 2>/dev/null || date +%s)"
  now="$(date +%s)"
  if ((now - last_used >= idle_seconds)); then
    echo "Qwen3-TTS idle timeout reached; stopping local model."
    stop_server
  fi
done

wait "$server_pid"
