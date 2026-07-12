#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)

find "$repo_root/docs/tracks" -maxdepth 1 -type f -name '*.md' -print |
  wc -l |
  tr -d ' '
