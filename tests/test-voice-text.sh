#!/usr/bin/env bash

set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
normalizer="$root/client/voice-text.sh"

assert_contains() {
  local haystack="$1" needle="$2"
  [[ "$haystack" == *"$needle"* ]] || {
    echo "Expected normalized text to contain: $needle" >&2
    exit 1
  }
}

assert_not_contains() {
  local haystack="$1" needle="$2"
  [[ "$haystack" != *"$needle"* ]] || {
    echo "Expected normalized text not to contain: $needle" >&2
    exit 1
  }
}

result="$(printf '%b' '**任务完成**\n详情见 [报告](https://example.com)。文件在 /Users/example/private/result.log。' | "$normalizer")"
assert_contains "$result" '任务完成'
assert_contains "$result" '报告'
assert_not_contains "$result" '**'
assert_not_contains "$result" 'https://'
assert_not_contains "$result" '/Users/'

result="$(printf '%s' '版本 v2.3.1 已发布。`make check` 全部通过。' | "$normalizer")"
assert_contains "$result" '版本 v2.3.1 已发布'
assert_contains "$result" 'make check 全部通过'
assert_not_contains "$result" '`'

result="$(printf '第一行\n\n第二行   内容' | "$normalizer")"
[[ "$result" == '第一行。第二行 内容' ]] || {
  echo "Unexpected whitespace normalization: $result" >&2
  exit 1
}

echo 'Voice text tests passed.'
