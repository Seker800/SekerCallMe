#!/usr/bin/env bash

set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

for script in scripts/*.sh client/*.sh; do
  bash -n "$script"
done

if compgen -G 'tests/*.sh' >/dev/null; then
  for script in tests/*.sh; do
    bash -n "$script"
  done
  ./tests/run.sh
fi

if [[ -f .env ]]; then
  docker compose config --quiet
else
  docker compose --env-file .env.example config --quiet
fi

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  if git ls-files --error-unmatch .env >/dev/null 2>&1; then
    echo '.env must not be tracked by Git.' >&2
    exit 1
  fi
fi

echo "Static checks passed."
