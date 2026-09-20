#!/usr/bin/env bash

set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
installer="$root/scripts/install-qwen-tts.sh"
server="$root/client/qwen-tts-server.sh"
wake="$root/client/qwen-tts-wake.sh"

grep -q '^SEKER_QWEN_TTS_IDLE_SECONDS=1200$' "$root/.env.example"
grep -q 'SEKER_QWEN_TTS_IDLE_SECONDS:-1200' "$server"

plist_call="$(sed -n '/^install_launch_agent_plist/,/qwen-tts-wake.sh/p' "$installer")"
[[ "$(grep -c '^[[:space:]]*false' <<<"$plist_call")" -eq 2 ]]

[[ -x "$wake" ]]
grep -q 'qwen-tts-wake.sh' "$root/client/speak.sh"

echo 'Qwen idle lifecycle tests passed.'
