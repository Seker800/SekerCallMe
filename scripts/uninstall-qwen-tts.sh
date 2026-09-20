#!/usr/bin/env bash

set -euo pipefail

label="com.seker.callme.qwen-tts"
plist_path="${HOME}/Library/LaunchAgents/${label}.plist"
uid="$(id -u)"

launchctl bootout "gui/${uid}" "$plist_path" >/dev/null 2>&1 || true
if [[ -f "$plist_path" ]]; then
  mv "$plist_path" "${HOME}/.Trash/${label}.plist"
fi

echo 'Qwen3-TTS LaunchAgent removed. Downloaded model files were preserved.'
