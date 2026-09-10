#!/usr/bin/env bash

set -euo pipefail

label="com.seker.callme.voice"
plist_path="${HOME}/Library/LaunchAgents/${label}.plist"
uid="$(id -u)"

if [[ -f "$plist_path" ]]; then
  launchctl bootout "gui/${uid}" "$plist_path" >/dev/null 2>&1 || true
  rm "$plist_path"
fi

echo "Voice subscriber removed: ${label}"
