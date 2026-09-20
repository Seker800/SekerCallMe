#!/usr/bin/env bash

set -euo pipefail

[[ "$(uname -s)" == Darwin ]] || {
  echo 'LaunchAgent plist tests skipped outside macOS.'
  exit 0
}

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../scripts/lib.sh
source "$root/scripts/lib.sh"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT
plist_path="$tmp_dir/Agent & Voice.plist"
program_path="$tmp_dir/Program & Voice.sh"

write_launch_agent_plist \
  "$plist_path" \
  com.example.voice-test \
  false \
  false \
  Interactive \
  "$tmp_dir/out & log" \
  "$tmp_dir/error & log" \
  63 \
  /usr/bin/env \
  -i \
  PATH=/usr/bin:/bin \
  "$program_path"

plutil -lint "$plist_path" >/dev/null
[[ "$(plutil -extract ProgramArguments.3 raw "$plist_path")" == "$program_path" ]]
[[ "$(stat -f '%Lp' "$plist_path")" == 600 ]]

echo 'LaunchAgent plist tests passed.'
