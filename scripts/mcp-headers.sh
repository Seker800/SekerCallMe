#!/usr/bin/env bash

# Codex http_headers_helper for this server host. It keeps the bearer token out
# of ~/.codex/config.toml and returns it only to the local Codex process.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib.sh
source "$root/scripts/lib.sh"
load_env

printf '{"Authorization":"Bearer %s"}\n' "$MCP_ACCESS_TOKEN"
