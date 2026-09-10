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
  set -a
  # shellcheck disable=SC1091
  source "$root/.env"
  set +a

  validate_env
}

validate_env() {
  local name value

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
  if [[ -n "${NTFY_UPSTREAM_BASE_URL:-}" && ! "$NTFY_UPSTREAM_BASE_URL" =~ ^https://[A-Za-z0-9./:_-]+$ ]]; then
    echo 'NTFY_UPSTREAM_BASE_URL must be empty or an HTTPS URL.' >&2
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
