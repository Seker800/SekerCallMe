#!/usr/bin/env bash

set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
wake="$root/client/qwen-tts-wake.sh"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT
bin_dir="$tmp_dir/bin"
mkdir -p "$bin_dir" "$tmp_dir/runtime"

cat >"$bin_dir/curl" <<'SCRIPT'
#!/usr/bin/env bash
[[ -f "$TEST_HEALTHY" ]]
SCRIPT

cat >"$bin_dir/launchctl" <<'SCRIPT'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$TEST_CALLS"
touch "$TEST_HEALTHY"
SCRIPT

cat >"$bin_dir/id" <<'SCRIPT'
#!/usr/bin/env bash
printf '501\n'
SCRIPT

cat >"$bin_dir/sleep" <<'SCRIPT'
#!/usr/bin/env bash
exit 0
SCRIPT

chmod +x "$bin_dir"/*
export PATH="$bin_dir:$PATH"
export TEST_CALLS="$tmp_dir/calls"
export TEST_HEALTHY="$tmp_dir/healthy"
export SEKER_RUNTIME_DIR="$tmp_dir/runtime"
export SEKER_QWEN_TTS_STARTUP_TIMEOUT=2

ln -s 999999 "$SEKER_RUNTIME_DIR/qwen-tts.wake.lock"
"$wake"
grep -q '^kickstart -k gui/501/com.seker.callme.qwen-tts$' "$TEST_CALLS"
[[ ! -L "$SEKER_RUNTIME_DIR/qwen-tts.wake.lock" ]]

: >"$TEST_CALLS"
"$wake"
[[ ! -s "$TEST_CALLS" ]]

echo 'Qwen wake recovery tests passed.'
