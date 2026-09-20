#!/usr/bin/env bash

set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../scripts/lib.sh
source "$root/scripts/lib.sh"

require_command curl
require_command jq
require_command shasum
load_env

stream_url="http://${LAN_HOST}:${NTFY_PORT}/${NTFY_TOPIC}/json"
dedup_seconds="${SEKER_VOICE_DEDUP_SECONDS:-120}"
dedup_state="$root/runtime/voice-subscriber.last"

if [[ ! "$dedup_seconds" =~ ^[0-9]{1,4}$ ]]; then
  echo 'SEKER_VOICE_DEDUP_SECONDS must be an integer between 0 and 9999.' >&2
  exit 1
fi

mkdir -p "$root/runtime"
echo "Voice subscriber started for ${LAN_HOST}:${NTFY_PORT}."

while true; do
  while IFS= read -r event; do
    [[ "$(jq -r '.event // empty' <<<"$event")" == "message" ]] || continue

    message="$(jq -r '(.message // "") | tostring | .[0:600]' <<<"$event")"
    [[ -n "$message" ]] || continue

    speech_text="$(printf '%s' "$message" | "$root/client/voice-text.sh")"
    [[ -n "$speech_text" ]] || continue

    now="$(date +%s)"
    speech_hash="$(printf '%s' "$speech_text" | shasum -a 256 | awk '{print $1}')"
    last_time=0
    last_hash=''
    if [[ -f "$dedup_state" ]]; then
      IFS=' ' read -r last_time last_hash <"$dedup_state" || true
    fi
    if ((dedup_seconds > 0)) && \
      [[ "$last_time" =~ ^[0-9]+$ ]] && \
      [[ "$last_hash" == "$speech_hash" ]] && \
      ((now - last_time <= dedup_seconds)); then
      echo 'Skipping duplicate voice notification.'
      continue
    fi

    event_id="$(jq -r '.id // "unknown"' <<<"$event")"
    echo "Speaking notification ${event_id}."
    if "$root/client/speak.sh" "$speech_text"; then
      printf '%s %s\n' "$now" "$speech_hash" >"${dedup_state}.tmp"
      mv "${dedup_state}.tmp" "$dedup_state"
    fi
  done < <(/usr/bin/curl -fsSN \
    --connect-timeout 10 \
    -u "${NTFY_USER}:${NTFY_PASSWORD}" \
    "$stream_url")

  echo 'Notification stream disconnected; reconnecting in 2 seconds.' >&2
  sleep 2
done
