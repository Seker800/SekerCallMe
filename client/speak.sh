#!/usr/bin/env bash

set -euo pipefail

provider="${SEKER_SPEECH_PROVIDER:-auto}"
voice="${SEKER_VOICE:-Tingting}"
voice_rate="${SEKER_VOICE_RATE:-170}"
qwen_url="${SEKER_QWEN_TTS_URL:-http://127.0.0.1:8785/v1/tts}"
qwen_voice="${SEKER_QWEN_TTS_VOICE:-vivian}"
qwen_language="${SEKER_QWEN_TTS_LANGUAGE:-Chinese}"
qwen_rate="${SEKER_QWEN_TTS_RATE:-1.0}"
qwen_timeout="${SEKER_QWEN_TTS_TIMEOUT:-30}"
text="${1:-}"

[[ -n "$text" ]] || exit 0

case "$provider" in
  auto|qwen|say) ;;
  *)
    echo 'SEKER_SPEECH_PROVIDER must be auto, qwen, or say.' >&2
    exit 1
    ;;
esac

if [[ "$provider" != say ]]; then
  audio_file="$(mktemp "${TMPDIR:-/tmp}/let-agent-speak.XXXXXX")"
  cleanup() {
    rm -f "$audio_file"
  }
  trap cleanup EXIT

  payload="$(jq -cn \
    --arg text "$text" \
    --arg speaker "$qwen_voice" \
    --arg language "$qwen_language" \
    --argjson rate "$qwen_rate" \
    '{text: $text, speaker: $speaker, language: $language, rate: $rate}')"

  if "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/qwen-tts-wake.sh" && \
    curl -fsS \
    --connect-timeout 1 \
    --max-time "$qwen_timeout" \
    -H 'Content-Type: application/json' \
    -d "$payload" \
    -o "$audio_file" \
    "$qwen_url" && \
    [[ "$(head -c 4 "$audio_file" 2>/dev/null || true)" == RIFF ]]; then
    touch "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/runtime/qwen-tts.last-used"
    afplay "$audio_file"
    exit 0
  fi

  echo 'Neural speech unavailable; using the macOS system voice.' >&2
fi

printf '%s' "$text" | /usr/bin/env say -v "$voice" -r "$voice_rate" -f -
