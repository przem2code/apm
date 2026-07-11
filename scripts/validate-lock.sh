#!/usr/bin/env bash
# Warn when apm.lock.yaml is stale relative to apm.yml.
set -euo pipefail

cd "$(dirname "$0")/.."

[ -f apm.lock.yaml ] || { echo "validate-lock: apm.lock.yaml missing" >&2; exit 1; }

# Stale when the manifest is newer than the lock file.
if [ apm.lock.yaml -nt apm.yml ]; then
  echo "validate-lock: apm.lock.yaml is stale; run 'apm install' to refresh" >&2
  exit 1
fi
echo "validate-lock: lock file is up to date"
