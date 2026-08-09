#!/usr/bin/env bash
# Exercises proposal-discipline-gate.sh as a real subprocess.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
HOOKS="$HERE/../hooks"
ROOT="$(cd "$HERE/../.." && pwd -P)"

# on-the-record test-env resolution convention (docs/specs/test-env-resolution.md, #551)
_tenv_out="$(cd "$ROOT" && python3 -m gates.test_env_resolve "$ROOT/../../core" "$ROOT/../../../core")"
_tenv_rc=$?
if [ "$_tenv_rc" -eq 75 ]; then
  exit 75
elif [ "$_tenv_rc" -ne 0 ]; then
  echo "$(basename "${BASH_SOURCE[0]}"): test-env resolution failed unexpectedly (rc=$_tenv_rc)" >&2
  exit 2
fi
export CLAUDE_PLUGIN_ROOT_CORE="$_tenv_out"

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

run_raw_payload() { # want name payload_json [extra_env]
  td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"; mkdir -p "$td/$(dirname "$PROPOSAL_PATH")"
  printf '%s' "$3" | env CLAUDE_PROJECT_DIR="$td" ${4:-} /bin/bash "$HOOKS/proposal-discipline-gate.sh" >/dev/null 2>&1
  rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"; report "$1" "$got" "$2"
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
run deny  kill-switch-unrecognized "$PROPOSAL_PATH"       "$MISSING_STATUS"    "PROPOSAL_DISCIPLINE_GATE_OFF=xyz"

run_absolute_path() {
  td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"; mkdir -p "$td/$(dirname "$PROPOSAL_PATH")"
  python3 -c 'import json,sys; print(json.dumps({"tool_name":"Write","tool_input":{"file_path":sys.argv[1],"content":sys.argv[2]},"cwd":sys.argv[3]}))' \
    "$td/$PROPOSAL_PATH" "$MISSING_STATUS" "$td" > "$td/.payload.json"
  /bin/bash "$HOOKS/proposal-discipline-gate.sh" < "$td/.payload.json" >/dev/null 2>&1
  rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"; report deny "$got" absolute-path
}
run_absolute_path

run deny  dot-prefixed-path "./$PROPOSAL_PATH" "$MISSING_STATUS"

run_edit_replace_all() {
  td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"; mkdir -p "$td/$(dirname "$PROPOSAL_PATH")"
  printf 'FILLER FILLER\n' > "$td/$PROPOSAL_PATH"
  payload='{"tool_name":"Edit","tool_input":{"file_path":"'"$PROPOSAL_PATH"'","old_string":"FILLER","new_string":"placeholder","replace_all":true},"cwd":"'"$td"'"}'
  printf '%s' "$payload" | env CLAUDE_PROJECT_DIR="$td" /bin/bash "$HOOKS/proposal-discipline-gate.sh" >/dev/null 2>&1
  rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"; report deny "$got" edit-replace_all-all-occurrences-checked
}
run_edit_replace_all

run_multiedit_mixed() {
  td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"; mkdir -p "$td/$(dirname "$PROPOSAL_PATH")"
  printf 'HEADING\nBODY\n' > "$td/$PROPOSAL_PATH"
  py_content="$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$ALL_SEVEN")"
  payload='{"tool_name":"MultiEdit","tool_input":{"file_path":"'"$PROPOSAL_PATH"'","edits":[{"old_string":"HEADING","new_string":"placeholder-a","replace_all":true},{"old_string":"placeholder-a\nBODY","new_string":'"$py_content"',"replace_all":false}]},"cwd":"'"$td"'"}'
  printf '%s' "$payload" | env CLAUDE_PROJECT_DIR="$td" /bin/bash "$HOOKS/proposal-discipline-gate.sh" >/dev/null 2>&1
  rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"; report allow "$got" multiedit-mixed-replace_all
}
run_multiedit_mixed

run_raw_payload deny malformed-json-truncated '{"tool_name":"Write","tool_input":{'
run_raw_payload deny malformed-json-non-object '["not","an","object"]'
run_raw_payload deny malformed-json-empty ''

# D10: a bare Edit (not Write, not MultiEdit) that completes a
# six-of-seven-section fixture to all seven, asserted allow — closes the
# gap where every existing allow-path case routed through Write/MultiEdit.
run_edit_plain_allow() {
  td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"; mkdir -p "$td/$(dirname "$PROPOSAL_PATH")"
  printf '%s' "$MISSING_STATUS" > "$td/$PROPOSAL_PATH"
  py_old="$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$MISSING_STATUS")"
  py_new="$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1] + "\n\n## Status\napproved"))' "$MISSING_STATUS")"
  payload='{"tool_name":"Edit","tool_input":{"file_path":"'"$PROPOSAL_PATH"'","old_string":'"$py_old"',"new_string":'"$py_new"'},"cwd":"'"$td"'"}'
  printf '%s' "$payload" | env CLAUDE_PROJECT_DIR="$td" /bin/bash "$HOOKS/proposal-discipline-gate.sh" >/dev/null 2>&1
  rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"; report allow "$got" edit-plain-completes-all-seven
}
run_edit_plain_allow

# missing-core: with no CLAUDE_PLUGIN_ROOT_CORE and no reachable sibling
# checkout, the resolver must SKIP (exit 75), per the test-env resolution
# convention (docs/specs/test-env-resolution.md, #551) — asserted directly
# against the resolver, not the hook subprocess.
run_missing_core() {
  out_rc=0
  ( cd "$ROOT" && env -u CLAUDE_PLUGIN_ROOT_CORE python3 -m gates.test_env_resolve "/no/such/core-a" "/no/such/core-b" ) >/dev/null 2>&1 || out_rc=$?
  case "$out_rc" in 75) got=skip ;; *) got="exit-$out_rc" ;; esac
  report skip "$got" missing-core
}
run_missing_core

printf '\n== %d passed, %d failed ==\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
