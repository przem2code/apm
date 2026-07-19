#!/usr/bin/env bash
# Pre-flight failure modes of the framework-modernizer eval runner.
#
# The runner must never turn a missing fixture tree or a missing expected file
# into a raw ENOENT stack trace, and must never let a zero-findings scan pass.
# Runs against a scratch copy of evals/ so the real fixture is never mutated.
set -uo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
SRC_EVALS="$REPO_ROOT/.apm/skills/framework-modernizer/evals"

SCRATCH=$(mktemp -d)
trap 'rm -rf "$SCRATCH"' EXIT

cp -R "$SRC_EVALS" "$SCRATCH/evals"
RUNNER="$SCRATCH/evals/run.js"
FIXTURE_DIR="$SCRATCH/evals/fixtures/express4-app"
EXPECTED_FILE="$SCRATCH/evals/expected/findings.txt"

failures=0

fail() {
  echo "  ❌ $1"
  failures=$((failures + 1))
}

# Case A: happy path — unmodified copy exits 0.
echo "[1/3] happy path"
out=$(node "$RUNNER" 2>&1)
status=$?
if [ "$status" -ne 0 ]; then
  fail "expected exit 0, got $status"
  echo "$out"
elif ! printf '%s' "$out" | grep -q 'PASSED'; then
  fail "expected a PASSED line, got: $out"
else
  echo "  ✅ exit 0 and PASSED"
fi

# Case B: fixture directory absent — exit 1, path named, no stack trace.
echo "[2/3] missing fixture dir"
mv "$FIXTURE_DIR" "$SCRATCH/fixture-backup"
out=$(node "$RUNNER" 2>&1)
status=$?
if [ "$status" -ne 1 ]; then
  fail "expected exit 1, got $status"
elif ! printf '%s' "$out" | grep -qF "$FIXTURE_DIR"; then
  fail "output did not name the missing fixture path: $out"
elif printf '%s' "$out" | grep -qE 'at [A-Za-z_$][A-Za-z0-9_$]* \(|ENOENT'; then
  fail "output looks like a raw stack trace: $out"
else
  echo "  ✅ exit 1 naming the fixture path"
fi
mv "$SCRATCH/fixture-backup" "$FIXTURE_DIR"

# Case C: expected findings file absent — exit 1, path named, no stack trace.
echo "[3/3] missing expected findings file"
rm "$EXPECTED_FILE"
out=$(node "$RUNNER" 2>&1)
status=$?
if [ "$status" -ne 1 ]; then
  fail "expected exit 1, got $status"
elif ! printf '%s' "$out" | grep -qF "$EXPECTED_FILE"; then
  fail "output did not name the missing expected file: $out"
elif printf '%s' "$out" | grep -qE 'at [A-Za-z_$][A-Za-z0-9_$]* \(|ENOENT'; then
  fail "output looks like a raw stack trace: $out"
else
  echo "  ✅ exit 1 naming the expected file"
fi

if [ "$failures" -ne 0 ]; then
  echo "framework-modernizer evals pre-flight: $failures case(s) FAILED"
  exit 1
fi
echo "framework-modernizer evals pre-flight: all 3 cases PASSED"
