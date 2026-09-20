#!/usr/bin/env bash

set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib.sh
source "$root/scripts/lib.sh"

require_command curl
require_command git
require_command launchctl
require_command make
require_command plutil
load_env

[[ "$(uname -s)" == Darwin && "$(uname -m)" == arm64 ]] || {
  echo 'Local Qwen3-TTS installation requires an Apple Silicon Mac.' >&2
  exit 1
}

revision="e391ec5467b0218eeb175f4888ad65b259d1e7c7"
model_revision="85e237c12c027371202489a0ec509ded67b5e4b5"
upstream="https://github.com/gabriele-mastrapasqua/qwen3-tts.git"
install_dir="$root/runtime/qwen3-tts/$revision"
source_dir="$install_dir/source"
model_dir="$install_dir/model"
label="com.seker.callme.qwen-tts"
plist_path="${HOME}/Library/LaunchAgents/${label}.plist"
uid="$(id -u)"

mkdir -p "$install_dir" "$root/runtime" "${HOME}/Library/LaunchAgents"
chmod 700 "$install_dir"

if [[ ! -d "$source_dir/.git" ]]; then
  git clone --filter=blob:none --no-checkout "$upstream" "$source_dir"
  git -C "$source_dir" checkout --detach "$revision"
else
  current_revision="$(git -C "$source_dir" rev-parse HEAD)"
  [[ "$current_revision" == "$revision" ]] || {
    echo 'Installed Qwen3-TTS source has an unexpected revision.' >&2
    exit 1
  }
fi

apply_patch_once() {
  local patch_file="$1"
  if git -C "$source_dir" apply --reverse --check "$patch_file" >/dev/null 2>&1; then
    return 0
  fi
  git -C "$source_dir" apply --check "$patch_file"
  git -C "$source_dir" apply "$patch_file"
}

apply_patch_once "$root/patches/qwen3-tts-loopback.patch"
apply_patch_once "$root/patches/qwen3-tts-make-3.81.patch"
apply_patch_once "$root/patches/qwen3-tts-local-security.patch"
apply_patch_once "$root/patches/qwen3-tts-content-type.patch"

make -C "$source_dir" blas
"$source_dir/qwen_tts" --caps
"$source_dir/qwen_tts" --self-test

QWEN_MODEL_REVISION="$model_revision" \
  "$source_dir/download_model.sh" --model small --dir "$model_dir"
qwen_model_complete "$model_dir" || {
  echo 'Qwen3-TTS model download is incomplete.' >&2
  exit 1
}

install_launch_agent_plist \
  "$uid" \
  "$plist_path" \
  "$label" \
  false \
  false \
  Interactive \
  "$root/runtime/qwen-tts.log" \
  "$root/runtime/qwen-tts.error.log" \
  63 \
  /usr/bin/env \
  -i \
  PATH=/usr/bin:/bin:/usr/sbin:/sbin \
  LANG="${LANG:-en_US.UTF-8}" \
  "$root/client/qwen-tts-server.sh"
"$root/client/qwen-tts-wake.sh"

echo 'Qwen3-TTS installed and ready; it sleeps after the configured idle period.'
