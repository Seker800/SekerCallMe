#!/usr/bin/env bash

set -euo pipefail

perl -0777 -pe '
  s/\[([^\]]+)\]\((?:https?:\/\/|mailto:)[^)]+\)/$1/g;
  s{https?://\S+}{链接}g;
  s{(?<![[:alnum:]_])/(?:Users|private|tmp|var|opt|Volumes)/\S+}{文件}g;
  s/[`*_#>]+//g;
  s/^\s*[-+]\s+//mg;
  s/\r//g;
  s/[ \t]*\n+[ \t]*/。/g;
  s/[ \t]+/ /g;
  s/。{2,}/。/g;
  s/^\s+|\s+$//g;
'
