#!/usr/bin/env bash

set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
init_script="$root/scripts/init.sh"
ntfy_config="$root/config/ntfy-server.yml"

if grep -q 'http://127\.0\.0\.1:${NTFY_PORT}/v1/health' "$init_script"; then
  echo 'Initialization must check the address where the ntfy port is actually published.' >&2
  exit 1
fi
grep -q 'http://${LAN_HOST}:${NTFY_PORT}/v1/health' "$init_script"
grep -q 'chmod 600 "$root/.env"' "$root/scripts/lib.sh"
grep -q 'ntfy access --reset "$NTFY_USER"' "$init_script"
grep -q 'managed-ntfy-user' "$init_script"
grep -q '^up: validate-env$' "$root/Makefile"
grep -q 'install_launch_agent_plist' "$root/scripts/lib.sh"

if grep -q '^behind-proxy:[[:space:]]*true' "$ntfy_config"; then
  echo 'Directly published ntfy must not trust caller-supplied proxy headers.' >&2
  exit 1
fi

for variable in LAN_HOST MCP_ACCESS_TOKEN NTFY_USER NTFY_PASSWORD NTFY_TOPIC; do
  grep -Fq "\${${variable}:?" "$root/compose.yaml"
done

grep -q 'qwen_model_complete' "$root/scripts/install-qwen-tts.sh"
grep -q 'kickstart -k' "$root/client/qwen-tts-wake.sh"
grep -q 'request Content-Type is required' "$root/patches/qwen3-tts-content-type.patch"
grep -q 'header_end' "$root/patches/qwen3-tts-content-type.patch"

if grep -Eq 'echo .*NTFY_TOPIC' "$init_script"; then
  echo 'Initialization output must not disclose the private ntfy topic.' >&2
  exit 1
fi
if grep -Eq 'echo .*\$\{LAN_HOST\}' "$init_script" "$root/client/voice-subscriber.sh"; then
  echo 'Runtime logs must not disclose private network details.' >&2
  exit 1
fi

echo 'Server hardening tests passed.'
