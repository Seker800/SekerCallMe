#!/usr/bin/env bash

set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../scripts/lib.sh
source "$root/scripts/lib.sh"

export LAN_HOST=127.0.0.1
export MCP_PORT=3010
export NTFY_PORT=8080
export MCP_ACCESS_TOKEN=0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef
export NTFY_USER=test
export NTFY_PASSWORD=test
export NTFY_TOPIC=test

SEKER_SPEECH_PROVIDER=auto \
SEKER_QWEN_TTS_URL=http://127.0.0.1:8785/v1/tts \
validate_env

if (SEKER_QWEN_TTS_URL=http://0.0.0.0:8785/v1/tts validate_env) 2>/dev/null; then
  echo 'Non-loopback Qwen3-TTS URL should be rejected.' >&2
  exit 1
fi

if (SEKER_SPEECH_PROVIDER=unknown validate_env) 2>/dev/null; then
  echo 'Unknown speech provider should be rejected.' >&2
  exit 1
fi

SEKER_QWEN_TTS_IDLE_SECONDS=1200 validate_env
if (SEKER_QWEN_TTS_IDLE_SECONDS=0 validate_env) 2>/dev/null; then
  echo 'A zero Qwen3-TTS idle timeout should be rejected.' >&2
  exit 1
fi

echo 'Voice configuration tests passed.'
