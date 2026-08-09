#!/usr/bin/env bash
# Runs every facet/process gate plugin's own test file for this rulebook.
# Each plugin owns its test file; this harness only aggregates pass/fail,
# per docs/issue-10/proposals/requirements-engineering-enforcement.md §3.
#
# A sub-suite exits 75 (the on-the-record test-env resolution convention's
# SKIP contract, docs/specs/test-env-resolution.md, #551) when core is
# unreachable outside the spawn env — tallied as skip, never as fail.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT="$(cd "$HERE/.." && pwd -P)"

SUITES=(
  "req-id-gate/tests/req-id-gate-test.sh"
  "traceability-matrix-gate/tests/traceability-matrix-gate-test.sh"
  "ambiguity-resolution-gate/tests/ambiguity-resolution-gate-test.sh"
  "proposal-discipline-gate/tests/proposal-discipline-gate-test.sh"
)

fail=0
skip=0
for s in "${SUITES[@]}"; do
  echo "== $s =="
  bash "$ROOT/$s"
  rc=$?
  if [ "$rc" -eq 75 ]; then
    skip=$((skip+1))
  elif [ "$rc" -ne 0 ]; then
    fail=1
  fi
  echo
done

echo "== $skip suite(s) skipped (test-env unresolvable) =="
if [ "$fail" -eq 0 ]; then
  echo "== all plugin gate suites passed =="
else
  echo "== one or more plugin gate suites FAILED =="
fi
exit "$fail"
