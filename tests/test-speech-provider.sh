#!/usr/bin/env bash

set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
speaker="$root/client/speak.sh"
tmp_dir="$(mktemp -d)"
bin_dir="$tmp_dir/bin"
mkdir -p "$bin_dir"

cat >"$bin_dir/curl" <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail
printf 'curl %s\n' "$*" >>"$TEST_CALLS"
if [[ "$*" == *'/v1/health'* ]]; then
  exit 0
fi
output=''
while (($#)); do
  if [[ "$1" == '-o' ]]; then
    output="$2"
    shift 2
  else
    shift
  fi
done
if [[ "${TEST_CURL_FAIL:-0}" == '1' ]]; then
  exit 22
fi
printf 'RIFFmock-wave' >"$output"
SCRIPT

cat >"$bin_dir/afplay" <<'SCRIPT'
#!/usr/bin/env bash
printf 'afplay %s\n' "$*" >>"$TEST_CALLS"
SCRIPT

cat >"$bin_dir/say" <<'SCRIPT'
#!/usr/bin/env bash
printf 'say %s\n' "$*" >>"$TEST_CALLS"
SCRIPT

chmod +x "$bin_dir/curl" "$bin_dir/afplay" "$bin_dir/say"
export PATH="$bin_dir:$PATH"
export TEST_CALLS="$tmp_dir/calls"
export SEKER_QWEN_TTS_URL='http://127.0.0.1:8785/v1/tts'
export SEKER_QWEN_TTS_VOICE='vivian'
export SEKER_QWEN_TTS_LANGUAGE='Chinese'
export SEKER_VOICE='Tingting'
export SEKER_VOICE_RATE='170'

SEKER_SPEECH_PROVIDER=auto "$speaker" '测试成功。'
grep -q '^curl ' "$TEST_CALLS"
grep -q '^afplay ' "$TEST_CALLS"
if grep -q '^say ' "$TEST_CALLS"; then
  echo 'System voice should not run after successful neural synthesis.' >&2
  exit 1
fi

: >"$TEST_CALLS"
TEST_CURL_FAIL=1 SEKER_SPEECH_PROVIDER=auto "$speaker" '需要回退。'
grep -q '^curl ' "$TEST_CALLS"
grep -q '^say ' "$TEST_CALLS"

: >"$TEST_CALLS"
SEKER_SPEECH_PROVIDER=say "$speaker" '只用系统语音。'
grep -q '^say ' "$TEST_CALLS"
if grep -q '^curl ' "$TEST_CALLS"; then
  echo 'Qwen should not run when the system provider is selected.' >&2
  exit 1
fi

echo 'Speech provider tests passed.'
