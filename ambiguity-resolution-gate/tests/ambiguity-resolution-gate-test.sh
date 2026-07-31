#!/usr/bin/env bash
# Exercises hooks/ambiguity-resolution-gate.sh as a real subprocess.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
HOOKS="$HERE/../hooks"
pass=0; fail=0
report() { if [ "$2" = "$1" ]; then pass=$((pass+1)); printf 'ok     %-28s %s\n' "$3" "$2"; else fail=$((fail+1)); printf 'FAIL   %-28s want=%s got=%s\n' "$3" "$1" "$2"; fi; }

REC=docs/issue-10/reports/requirements-engineering.md

run() { # want name file content [extra_env]
  want="$1" name="$2" file="$3" content="$4" extra_env="${5:-}"
  td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
  payload="$(python3 -c '
import json, sys
print(json.dumps({"tool_name": "Write", "tool_input": {"file_path": sys.argv[1], "content": sys.argv[2]}, "cwd": sys.argv[3]}))
' "$file" "$content" "$td")"
  got_rc=0
  printf '%s' "$payload" | env CLAUDE_PROJECT_DIR="$td" $extra_env /bin/bash "$HOOKS/ambiguity-resolution-gate.sh" >/dev/null 2>&1 || got_rc=$?
  case "$got_rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$got_rc" ;; esac
  rm -rf "$td"
  report "$want" "$got" "$name"
}

run deny  no-ambiguity-section         "$REC" '# Requirements

## Requirements list
REQ-1: something.'

run deny  heading-only-no-resolution   "$REC" '# Requirements

## Ambiguity
- The term "fast" is ambiguous.'

run allow explicit-none-found          "$REC" '# Requirements

## Ambiguity
No ambiguities found during this review.'

run allow resolved-entry-present       "$REC" '# Requirements

## Ambiguity
- "fast" was ambiguous. Resolution: defined as < 200ms p95.'

run allow foreign-path                 "docs/issue-10/reports/other.md" 'no ambiguity section here at all'

run allow kill-switch-off              "$REC" '# Requirements

no ambiguity content whatsoever' "AMBIGUITY_RESOLUTION_GATE_OFF=1"

printf '\n== %d passed, %d failed ==\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
