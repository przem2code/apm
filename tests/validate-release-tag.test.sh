#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)
validator="$repo_root/scripts/validate-release-tag.sh"

"$validator" v1.2.3 >/dev/null

if "$validator" latest >/dev/null 2>&1; then
  printf 'expected latest to be rejected\n' >&2
  exit 1
fi

printf 'validate-release-tag: PASS\n'
