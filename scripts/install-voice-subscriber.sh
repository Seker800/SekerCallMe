#!/usr/bin/env bash

set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib.sh
source "$root/scripts/lib.sh"

require_command launchctl
require_command plutil
require_command jq
require_command afplay
require_command perl
require_command say
load_env

label="com.seker.callme.voice"
launch_agents_dir="${HOME}/Library/LaunchAgents"
plist_path="${launch_agents_dir}/${label}.plist"
runtime_dir="${root}/runtime"
uid="$(id -u)"

mkdir -p "$launch_agents_dir" "$runtime_dir"

cat >"$plist_path" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>${label}</string>
  <key>ProgramArguments</key>
  <array>
    <string>${root}/client/voice-subscriber.sh</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <true/>
  <key>ProcessType</key>
  <string>Background</string>
  <key>StandardOutPath</key>
  <string>${runtime_dir}/voice-subscriber.log</string>
  <key>StandardErrorPath</key>
  <string>${runtime_dir}/voice-subscriber.error.log</string>
</dict>
</plist>
PLIST

plutil -lint "$plist_path" >/dev/null
launchctl bootout "gui/${uid}" "$plist_path" >/dev/null 2>&1 || true
launchctl bootstrap "gui/${uid}" "$plist_path"
launchctl kickstart -k "gui/${uid}/${label}"

echo "Voice subscriber installed and running: ${label}"
