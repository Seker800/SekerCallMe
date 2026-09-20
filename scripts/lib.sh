#!/usr/bin/env bash

set -euo pipefail

project_dir() {
  cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd
}

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

load_env() {
  local root
  root="$(project_dir)"
  if [[ ! -f "$root/.env" ]]; then
    echo "Missing $root/.env. Run: make init" >&2
    exit 1
  fi
  chmod 600 "$root/.env"
  # shellcheck disable=SC1091
  source "$root/.env"

  validate_env
  unexport_env
}

load_env_private() {
  local root
  root="$(project_dir)"
  if [[ ! -f "$root/.env" ]]; then
    echo "Missing $root/.env. Run: make init" >&2
    exit 1
  fi
  chmod 600 "$root/.env"
  # shellcheck disable=SC1091
  source "$root/.env"
  validate_env
  unexport_env
}

unexport_env() {
  export -n \
    LAN_HOST MCP_PORT NTFY_PORT MCP_ACCESS_TOKEN NTFY_USER NTFY_PASSWORD NTFY_TOPIC \
    SEKER_VOICE SEKER_VOICE_RATE SEKER_SPEECH_PROVIDER SEKER_VOICE_DEDUP_SECONDS \
    SEKER_QWEN_TTS_PORT SEKER_QWEN_TTS_URL SEKER_QWEN_TTS_VOICE \
    SEKER_QWEN_TTS_LANGUAGE SEKER_QWEN_TTS_RATE SEKER_QWEN_TTS_TIMEOUT \
    SEKER_QWEN_TTS_STARTUP_TIMEOUT SEKER_QWEN_TTS_THREADS SEKER_QWEN_TTS_IDLE_SECONDS
}

qwen_model_complete() {
  local model_dir="$1" relative_path
  local required_files=(
    config.json
    generation_config.json
    tokenizer_config.json
    preprocessor_config.json
    model.safetensors
    vocab.json
    merges.txt
    speech_tokenizer/config.json
    speech_tokenizer/configuration.json
    speech_tokenizer/model.safetensors
    speech_tokenizer/preprocessor_config.json
  )

  for relative_path in "${required_files[@]}"; do
    [[ -s "$model_dir/$relative_path" ]] || return 1
  done
}

curl_config_escape() {
  local value="$1"
  [[ "$value" != *$'\n'* && "$value" != *$'\r'* ]] || return 1
  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  printf '%s' "$value"
}

curl_basic_config() {
  local username password url
  username="$(curl_config_escape "$1")"
  password="$(curl_config_escape "$2")"
  url="$(curl_config_escape "$3")"
  printf 'user = "%s:%s"\nurl = "%s"\n' "$username" "$password" "$url"
}

curl_bearer_config() {
  local token
  token="$(curl_config_escape "$1")"
  printf 'header = "Authorization: Bearer %s"\n' "$token"
}

write_launch_agent_plist() {
  local plist_path="$1" label="$2" run_at_load="$3" keep_alive="$4"
  local process_type="$5" stdout_path="$6" stderr_path="$7" agent_umask="$8"
  shift 8
  local temporary_plist argument_index=0 argument
  (($# > 0)) || return 1
  temporary_plist="$(mktemp "${plist_path}.tmp.XXXXXX")"

  if ! {
    plutil -create xml1 "$temporary_plist" &&
      plutil -insert Label -string "$label" "$temporary_plist" &&
      plutil -insert ProgramArguments -array "$temporary_plist" &&
      plutil -insert RunAtLoad -bool "$run_at_load" "$temporary_plist" &&
      plutil -insert KeepAlive -bool "$keep_alive" "$temporary_plist" &&
      plutil -insert ProcessType -string "$process_type" "$temporary_plist" &&
      plutil -insert StandardOutPath -string "$stdout_path" "$temporary_plist" &&
      plutil -insert StandardErrorPath -string "$stderr_path" "$temporary_plist" &&
      { [[ -z "$agent_umask" ]] || plutil -insert Umask -integer "$agent_umask" "$temporary_plist"; } &&
      plutil -lint "$temporary_plist" >/dev/null
  }; then
    rm -f "$temporary_plist"
    return 1
  fi

  for argument in "$@"; do
    plutil -insert "ProgramArguments.${argument_index}" -string "$argument" "$temporary_plist"
    ((argument_index += 1))
  done
  plutil -lint "$temporary_plist" >/dev/null

  chmod 600 "$temporary_plist"
  mv "$temporary_plist" "$plist_path"
}

install_launch_agent_plist() {
  local uid="$1" plist_path="$2" backup_path=''
  shift 2

  if [[ -f "$plist_path" ]]; then
    backup_path="$(mktemp "${plist_path}.backup.XXXXXX")"
    cp -p "$plist_path" "$backup_path"
  fi

  if ! write_launch_agent_plist "$plist_path" "$@"; then
    [[ -z "$backup_path" ]] || rm -f "$backup_path"
    return 1
  fi

  launchctl bootout "gui/${uid}" "$plist_path" >/dev/null 2>&1 || true
  if launchctl bootstrap "gui/${uid}" "$plist_path"; then
    [[ -z "$backup_path" ]] || rm -f "$backup_path"
    return 0
  fi

  if [[ -n "$backup_path" ]]; then
    mv "$backup_path" "$plist_path"
    launchctl bootstrap "gui/${uid}" "$plist_path" >/dev/null 2>&1 || true
  else
    rm -f "$plist_path"
  fi
  return 1
}

validate_env() {
  local name value qwen_language qwen_port qwen_rate qwen_url qwen_voice

  for name in LAN_HOST MCP_PORT NTFY_PORT MCP_ACCESS_TOKEN NTFY_USER NTFY_PASSWORD NTFY_TOPIC; do
    value="${!name:-}"
    if [[ -z "$value" ]]; then
      echo "Missing required value in .env: $name" >&2
      exit 1
    fi
  done

  if [[ ! "$LAN_HOST" =~ ^[A-Za-z0-9.-]+$ ]]; then
    echo 'LAN_HOST contains unsupported characters.' >&2
    exit 1
  fi
  for name in MCP_PORT NTFY_PORT; do
    value="${!name}"
    if [[ ! "$value" =~ ^[0-9]+$ ]] || ((value < 1 || value > 65535)); then
      echo "$name must be an integer between 1 and 65535." >&2
      exit 1
    fi
  done
  if [[ ! "$MCP_ACCESS_TOKEN" =~ ^[A-Fa-f0-9]{64}$ ]]; then
    echo 'MCP_ACCESS_TOKEN must be a 64-character hexadecimal token.' >&2
    exit 1
  fi
  if [[ ! "$NTFY_USER" =~ ^[A-Za-z0-9._-]+$ ]]; then
    echo 'NTFY_USER contains unsupported characters.' >&2
    exit 1
  fi
  if [[ ! "$NTFY_TOPIC" =~ ^[A-Za-z0-9_-]+$ ]]; then
    echo 'NTFY_TOPIC contains unsupported characters.' >&2
    exit 1
  fi

  value="${SEKER_VOICE_RATE:-170}"
  if [[ ! "$value" =~ ^[0-9]{2,3}$ ]] || ((10#$value < 80 || 10#$value > 500)); then
    echo 'SEKER_VOICE_RATE must be an integer between 80 and 500.' >&2
    exit 1
  fi
  if [[ ! "${SEKER_SPEECH_PROVIDER:-auto}" =~ ^(auto|qwen|say)$ ]]; then
    echo 'SEKER_SPEECH_PROVIDER must be auto, qwen, or say.' >&2
    exit 1
  fi
  value="${SEKER_VOICE_DEDUP_SECONDS:-120}"
  if [[ ! "$value" =~ ^[0-9]{1,4}$ ]]; then
    echo 'SEKER_VOICE_DEDUP_SECONDS must be an integer between 0 and 9999.' >&2
    exit 1
  fi

  qwen_port="${SEKER_QWEN_TTS_PORT:-8785}"
  if [[ ! "$qwen_port" =~ ^[0-9]+$ ]] || ((qwen_port < 1 || qwen_port > 65535)); then
    echo 'SEKER_QWEN_TTS_PORT must be an integer between 1 and 65535.' >&2
    exit 1
  fi
  qwen_url="${SEKER_QWEN_TTS_URL:-http://127.0.0.1:${qwen_port}/v1/tts}"
  if [[ "$qwen_url" != "http://127.0.0.1:${qwen_port}/v1/tts" ]]; then
    echo 'SEKER_QWEN_TTS_URL must use the configured loopback port and /v1/tts.' >&2
    exit 1
  fi
  qwen_voice="${SEKER_QWEN_TTS_VOICE:-vivian}"
  qwen_language="${SEKER_QWEN_TTS_LANGUAGE:-Chinese}"
  if [[ ! "$qwen_voice" =~ ^[A-Za-z0-9_-]+$ ]] || [[ ! "$qwen_language" =~ ^[A-Za-z]+$ ]]; then
    echo 'Qwen3-TTS voice or language contains unsupported characters.' >&2
    exit 1
  fi
  qwen_rate="${SEKER_QWEN_TTS_RATE:-1.0}"
  if [[ ! "$qwen_rate" =~ ^[0-9]+([.][0-9]+)?$ ]] || \
    ! awk -v rate="$qwen_rate" 'BEGIN { exit !(rate >= 0.25 && rate <= 4.0) }'; then
    echo 'SEKER_QWEN_TTS_RATE must be between 0.25 and 4.0.' >&2
    exit 1
  fi
  for name in SEKER_QWEN_TTS_TIMEOUT SEKER_QWEN_TTS_THREADS SEKER_QWEN_TTS_STARTUP_TIMEOUT; do
    value="${!name:-}"
    [[ -z "$value" ]] && continue
    if [[ ! "$value" =~ ^[0-9]+$ ]] || ((value < 1 || value > 120)); then
      echo "$name must be an integer between 1 and 120." >&2
      exit 1
    fi
  done
  value="${SEKER_QWEN_TTS_IDLE_SECONDS:-1200}"
  if [[ ! "$value" =~ ^[0-9]+$ ]] || ((value < 1 || value > 86400)); then
    echo 'SEKER_QWEN_TTS_IDLE_SECONDS must be an integer between 1 and 86400.' >&2
    exit 1
  fi
}

detect_lan_host() {
  local interface address
  interface="$(route -n get default 2>/dev/null | awk '/interface:/{print $2; exit}')"
  if [[ -n "$interface" ]] && command -v ipconfig >/dev/null 2>&1; then
    address="$(ipconfig getifaddr "$interface" 2>/dev/null || true)"
    if [[ -n "$address" ]]; then
      printf '%s' "$address"
      return
    fi
  fi
  hostname -I 2>/dev/null | awk '{print $1}'
}
