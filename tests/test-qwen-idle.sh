#!/usr/bin/env bash

set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
installer="$root/scripts/install-qwen-tts.sh"
server="$root/client/qwen-tts-server.sh"
wake="$root/client/qwen-tts-wake.sh"

grep -q '^SEKER_QWEN_TTS_IDLE_SECONDS=1200$' "$root/.env.example"
grep -q 'SEKER_QWEN_TTS_IDLE_SECONDS:-1200' "$server"

awk '
  /<key>RunAtLoad<\/key>/ { getline; run_at_load = $0 }
  /<key>KeepAlive<\/key>/ { getline; keep_alive = $0 }
  END {
    if (run_at_load !~ /<false\/>/ || keep_alive !~ /<false\/>/) exit 1
  }
' "$installer"

[[ -x "$wake" ]]
grep -q 'qwen-tts-wake.sh' "$root/client/speak.sh"

echo 'Qwen idle lifecycle tests passed.'
