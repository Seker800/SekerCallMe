#!/usr/bin/env bash

set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../scripts/lib.sh
source "$root/scripts/lib.sh"

require_command curl
require_command jq
require_command say
load_env

voice="${SEKER_VOICE:-Tingting}"
rate="${SEKER_VOICE_RATE:-190}"
stream_url="http://${LAN_HOST}:${NTFY_PORT}/${NTFY_TOPIC}/json"

if [[ ! "$rate" =~ ^[0-9]{2,3}$ ]]; then
  echo 'SEKER_VOICE_RATE must be an integer between 80 and 500.' >&2
  exit 1
fi
rate_number=$((10#$rate))
if ((rate_number < 80 || rate_number > 500)); then
  echo 'SEKER_VOICE_RATE must be an integer between 80 and 500.' >&2
  exit 1
fi

echo "Voice subscriber started for ${LAN_HOST}:${NTFY_PORT} using voice ${voice}."

while true; do
  while IFS= read -r event; do
    [[ "$(jq -r '.event // empty' <<<"$event")" == "message" ]] || continue

    title="$(jq -r '(.title // "Codex 通知") | tostring | .[0:120]' <<<"$event")"
    message="$(jq -r '(.message // "") | tostring | .[0:600]' <<<"$event")"
    [[ -n "$message" ]] || continue

    event_id="$(jq -r '.id // "unknown"' <<<"$event")"
    echo "Speaking notification ${event_id}."
    /usr/bin/say -v "$voice" -r "$rate" "${title}。${message}"
  done < <(/usr/bin/curl -fsSN \
    --connect-timeout 10 \
    -u "${NTFY_USER}:${NTFY_PASSWORD}" \
    "$stream_url")

  echo 'Notification stream disconnected; reconnecting in 2 seconds.' >&2
  sleep 2
done
