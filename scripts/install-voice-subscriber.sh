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

install_launch_agent_plist \
  "$uid" \
  "$plist_path" \
  "$label" \
  true \
  true \
  Background \
  "$runtime_dir/voice-subscriber.log" \
  "$runtime_dir/voice-subscriber.error.log" \
  '' \
  /usr/bin/env \
  -i \
  PATH=/usr/bin:/bin:/usr/sbin:/sbin \
  LANG="${LANG:-en_US.UTF-8}" \
  "$root/client/voice-subscriber.sh"
launchctl kickstart -k "gui/${uid}/${label}"

echo "Voice subscriber installed and running: ${label}"
