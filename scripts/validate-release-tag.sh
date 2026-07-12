#!/usr/bin/env bash
set -euo pipefail

tag=${1-}

if [[ "$tag" =~ v[0-9]+\.[0-9]+\.[0-9]+ ]]; then
  printf 'valid release tag: %s\n' "$tag"
  exit 0
fi

printf 'invalid release tag: %s\n' "$tag" >&2
exit 1
