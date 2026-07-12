#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)
validator="$repo_root/scripts/validate-release-tag.sh"

"$validator" v1.2.3 >/dev/null

for invalid in latest release-v1.2.3 v1.2.3-rc1 v1.2.3.4; do
  if "$validator" "$invalid" >/dev/null 2>&1; then
    printf 'expected %s to be rejected\n' "$invalid" >&2
    exit 1
  fi
done

printf 'validate-release-tag: PASS\n'
