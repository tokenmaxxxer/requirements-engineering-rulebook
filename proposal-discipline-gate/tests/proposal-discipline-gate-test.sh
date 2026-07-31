#!/usr/bin/env bash
# Exercises proposal-discipline-gate.sh as a real subprocess.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
HOOKS="$HERE/../hooks"
pass=0; fail=0
report() { if [ "$2" = "$1" ]; then pass=$((pass+1)); printf 'ok     %-28s %s\n' "$3" "$2"; else fail=$((fail+1)); printf 'FAIL   %-28s want=%s got=%s\n' "$3" "$1" "$2"; fi; }

PROPOSAL_PATH="docs/issue-10/proposals/requirements-engineering-enforcement.md"

run() { # want name file content [extra_env=]
  local want="$1" name="$2" file="$3" content="$4" extra_env="${5:-}"
  td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"; mkdir -p "$td/$(dirname "$file")"
  payload_file="$td/.payload.json"
  python3 -c 'import json,sys; print(json.dumps({"tool_name":"Write","tool_input":{"file_path":sys.argv[1],"content":sys.argv[2]},"cwd":sys.argv[3]}))' \
    "$file" "$content" "$td" > "$payload_file"
  env CLAUDE_PROJECT_DIR="$td" $extra_env /bin/bash "$HOOKS/proposal-discipline-gate.sh" < "$payload_file" >/dev/null 2>&1
  rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"; report "$want" "$got" "$name"
}

ALL_SEVEN='## Problem / Scope
Text about the problem and scope.

## Survey-Basis
Based on survey.md current-state survey.

## Adopted Norm
We adopt X.

## Rejected Alternative
We rejected Y.

## Plugin-Reflection
Reflected into plugin Z.

## Verification Plan
We will verify via tests.

## Status
approved'

MISSING_STATUS='## Problem / Scope
Text.

## Survey-Basis
survey.md

## Adopted Norm
adopted norm here

## Rejected Alternative
rejected alternative here

## Plugin-Reflection
plugin-reflection here

## Verification Plan
verification plan here'

MISSING_ADOPTED_NORM='## Problem / Scope
Text.

## Survey-Basis
survey.md

## Rejected Alternative
rejected alternative here

## Plugin-Reflection
plugin-reflection here

## Verification Plan
verification plan here

## Status
draft'

run allow all-seven-sections    "$PROPOSAL_PATH"          "$ALL_SEVEN"         ""
run deny  missing-status        "$PROPOSAL_PATH"          "$MISSING_STATUS"    ""
run deny  missing-adopted-norm  "$PROPOSAL_PATH"          "$MISSING_ADOPTED_NORM" ""
run allow foreign-path          "docs/issue-10/reports/requirements-engineering.md" "$MISSING_STATUS" ""
run allow kill-switch-off       "$PROPOSAL_PATH"          "$MISSING_STATUS"    "PROPOSAL_DISCIPLINE_GATE_OFF=1"

printf '\n== %d passed, %d failed ==\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
