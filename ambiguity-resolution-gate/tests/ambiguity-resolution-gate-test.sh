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
  td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"; mkdir -p "$td/$(dirname "$file")"
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

run_raw_payload() { # want name payload_json [extra_env]
  td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"; mkdir -p "$td/$(dirname "$REC")"
  got_rc=0
  printf '%s' "$3" | env CLAUDE_PROJECT_DIR="$td" ${4:-} /bin/bash "$HOOKS/ambiguity-resolution-gate.sh" >/dev/null 2>&1 || got_rc=$?
  case "$got_rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$got_rc" ;; esac
  rm -rf "$td"
  report "$1" "$got" "$2"
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

run deny  kill-switch-unrecognized     "$REC" '# Requirements

no ambiguity content whatsoever' "AMBIGUITY_RESOLUTION_GATE_OFF=xyz"

run_absolute_path() {
  td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"; mkdir -p "$td/$(dirname "$REC")"
  payload="$(python3 -c '
import json, sys
print(json.dumps({"tool_name": "Write", "tool_input": {"file_path": sys.argv[1], "content": sys.argv[2]}, "cwd": sys.argv[3]}))
' "$td/$REC" 'no ambiguity content whatsoever' "$td")"
  got_rc=0
  printf '%s' "$payload" | env CLAUDE_PROJECT_DIR="$td" /bin/bash "$HOOKS/ambiguity-resolution-gate.sh" >/dev/null 2>&1 || got_rc=$?
  case "$got_rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$got_rc" ;; esac
  rm -rf "$td"
  report deny "$got" absolute-path
}
run_absolute_path

run deny  dot-prefixed-path "./$REC" 'no ambiguity content whatsoever'

run_edit_replace_all() {
  td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"; mkdir -p "$td/$(dirname "$REC")"
  printf 'FILLER FILLER\n' > "$td/$REC"
  payload='{"tool_name":"Edit","tool_input":{"file_path":"'"$REC"'","old_string":"FILLER","new_string":"placeholder","replace_all":true},"cwd":"'"$td"'"}'
  got_rc=0
  printf '%s' "$payload" | env CLAUDE_PROJECT_DIR="$td" /bin/bash "$HOOKS/ambiguity-resolution-gate.sh" >/dev/null 2>&1 || got_rc=$?
  case "$got_rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$got_rc" ;; esac
  rm -rf "$td"
  report deny "$got" edit-replace_all-all-occurrences-checked
}
run_edit_replace_all

run_multiedit_mixed() {
  td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"; mkdir -p "$td/$(dirname "$REC")"
  printf 'HEADING\nBODY\n' > "$td/$REC"
  payload='{"tool_name":"MultiEdit","tool_input":{"file_path":"'"$REC"'","edits":[{"old_string":"HEADING","new_string":"placeholder-a","replace_all":true},{"old_string":"placeholder-a\nBODY","new_string":"## Ambiguity\nNo ambiguities found.","replace_all":false}]},"cwd":"'"$td"'"}'
  got_rc=0
  printf '%s' "$payload" | env CLAUDE_PROJECT_DIR="$td" /bin/bash "$HOOKS/ambiguity-resolution-gate.sh" >/dev/null 2>&1 || got_rc=$?
  case "$got_rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$got_rc" ;; esac
  rm -rf "$td"
  report allow "$got" multiedit-mixed-replace_all
}
run_multiedit_mixed

run_raw_payload deny malformed-json-truncated '{"tool_name":"Write","tool_input":{'
run_raw_payload deny malformed-json-non-object '["not","an","object"]'
run_raw_payload deny malformed-json-empty ''

# missing-core: CLAUDE_PLUGIN_ROOT_CORE pointed at a nonexistent path must
# deny (exit 2), not silently allow (core issue-75 fix; the || guard on the
# gate-lib.sh source line must trip here).
run_missing_core() {
  td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"; mkdir -p "$td/$(dirname "$REC")"
  payload="$(python3 -c '
import json, sys
print(json.dumps({"tool_name": "Write", "tool_input": {"file_path": sys.argv[1], "content": sys.argv[2]}, "cwd": sys.argv[3]}))
' "$REC" "no ambiguity content here" "$td")"
  got_rc=0
  printf '%s' "$payload" | env CLAUDE_PROJECT_DIR="$td" CLAUDE_PLUGIN_ROOT_CORE="$td/no-such-core" /bin/bash "$HOOKS/ambiguity-resolution-gate.sh" >/dev/null 2>&1 || got_rc=$?
  case "$got_rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$got_rc" ;; esac
  rm -rf "$td"
  report deny "$got" missing-core
}
run_missing_core

printf '\n== %d passed, %d failed ==\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
