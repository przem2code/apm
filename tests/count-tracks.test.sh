#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)
actual=$($repo_root/scripts/count-tracks.sh)

if [[ "$actual" != "4" ]]; then
  printf 'expected 4 workshop tracks, got %s\n' "$actual" >&2
  exit 1
fi

printf 'count-tracks: PASS\n'
