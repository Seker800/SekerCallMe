#!/usr/bin/env bash

set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

for test_script in "$root"/tests/test-*.sh; do
  "$test_script"
done
