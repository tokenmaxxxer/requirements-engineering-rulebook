#!/usr/bin/env bash
# Test harness for traceability-matrix-gate.sh, exercised as a real subprocess.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
HOOKS="$HERE/../hooks"
pass=0; fail=0
report() { if [ "$2" = "$1" ]; then pass=$((pass+1)); printf 'ok     %-28s %s\n' "$3" "$2"; else fail=$((fail+1)); printf 'FAIL   %-28s want=%s got=%s\n' "$3" "$1" "$2"; fi; }

REC=docs/issue-7/reports/requirements-engineering.md

run() { # want name file content [extra_env=...]
  want="$1" name="$2" file="$3" content="$4" extra_env="${5:-}"
  td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"; mkdir -p "$td/docs/issue-7/reports"
  payload="$(printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":%s},"cwd":"%s"}' \
    "$file" "$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$content")" "$td")"
  printf '%s' "$payload" \
    | env CLAUDE_PROJECT_DIR="$td" $extra_env /bin/bash "$HOOKS/traceability-matrix-gate.sh" >/dev/null 2>&1
  rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"; report "$want" "$got" "$name"
}

run_raw_payload() { # want name payload_json [extra_env]
  td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"; mkdir -p "$td/docs/issue-7/reports"
  printf '%s' "$3" | env CLAUDE_PROJECT_DIR="$td" ${4:-} /bin/bash "$HOOKS/traceability-matrix-gate.sh" >/dev/null 2>&1
  rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"; report "$1" "$got" "$2"
}

NO_MATRIX='# Requirements Record
## Requirements
- REQ-1: something
'

MISSING_COLUMN='# Requirements Record
## Traceability Matrix
| ID | Description | Downstream Link |
| --- | --- | --- |
| REQ-1 | something | link |
'

MISSING_ROW='# Requirements Record
## Requirements
- REQ-1: something
- REQ-2: something else

## Traceability Matrix
| ID | Description | Source | Downstream Link |
| --- | --- | --- | --- |
| REQ-1 | something | src | link |
'

COMPLETE_MATRIX='# Requirements Record
## Requirements
- REQ-1: something
- REQ-2: something else

## Traceability Matrix
| ID | Description | Source | Downstream Link |
| --- | --- | --- | --- |
| REQ-1 | something | src/file.py | abc1234 |
| REQ-2 | something else | src/other.py | abc1234def |
'

# D2 regression guard: the section contains the bare word "valid" (an
# 'id'-superstring) and prose mentioning description/source/downstream, but
# no actual markdown table — the exact substring bug named in the issue
# ('id' matching inside 'valid') must no longer allow this.
D2_SUBSTRING_TRAP='# Requirements Record
## Requirements
- REQ-1: something

## Traceability Matrix
This section is valid and has a guide to description, source, and
downstream references, but carries no real table structure at all.
'

run deny  no-matrix-section     "$REC" "$NO_MATRIX"
run deny  missing-column        "$REC" "$MISSING_COLUMN"
run deny  missing-row-for-id    "$REC" "$MISSING_ROW"
run allow complete-matrix       "$REC" "$COMPLETE_MATRIX"
run allow foreign-path          "docs/issue-7/reports/qa.md" "no matrix here at all"
run allow kill-switch-off       "$REC" "$NO_MATRIX" "TRACEABILITY_MATRIX_GATE_OFF=1"
run deny  kill-switch-unrecognized "$REC" "$NO_MATRIX" "TRACEABILITY_MATRIX_GATE_OFF=xyz"
run deny  d2-substring-regression "$REC" "$D2_SUBSTRING_TRAP"

# D9 regression guard: a header cell literally "Resource" must not
# satisfy the "Source" column requirement (whole-cell match, not substring).
D9_RESOURCE_NOT_SOURCE='# Requirements Record
## Requirements
- REQ-1: something

## Traceability Matrix
| ID | Description | Resource | Downstream Link |
| --- | --- | --- | --- |
| REQ-1 | something | res | link |
'
run deny  d9-resource-not-source "$REC" "$D9_RESOURCE_NOT_SOURCE"

# absolute-path: an absolute file_path reaching the same scope a relative fixture already covers
run_absolute_path() {
  td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"; mkdir -p "$td/docs/issue-7/reports"
  payload="$(printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":%s},"cwd":"%s"}' \
    "$td/$REC" "$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$NO_MATRIX")" "$td")"
  printf '%s' "$payload" | env CLAUDE_PROJECT_DIR="$td" /bin/bash "$HOOKS/traceability-matrix-gate.sh" >/dev/null 2>&1
  rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"; report deny "$got" absolute-path
}
run_absolute_path

run deny  dot-prefixed-path "./$REC" "$NO_MATRIX"

# edit-replace_all: an Edit with replace_all:true against a multiply-occurring old_string
run_edit_replace_all() {
  td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"; mkdir -p "$td/docs/issue-7/reports"
  printf 'FILLER FILLER\n' > "$td/$REC"
  payload='{"tool_name":"Edit","tool_input":{"file_path":"'"$REC"'","old_string":"FILLER","new_string":"placeholder","replace_all":true},"cwd":"'"$td"'"}'
  printf '%s' "$payload" | env CLAUDE_PROJECT_DIR="$td" /bin/bash "$HOOKS/traceability-matrix-gate.sh" >/dev/null 2>&1
  rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"; report deny "$got" edit-replace_all-all-occurrences-checked
}
run_edit_replace_all

# multiedit-mixed-replace_all: a MultiEdit call mixing replace_all true/false, resulting in a complete matrix
run_multiedit_mixed() {
  td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"; mkdir -p "$td/docs/issue-7/reports"
  printf 'HEADING\nREQS\n' > "$td/$REC"
  py_content="$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$COMPLETE_MATRIX")"
  payload='{"tool_name":"MultiEdit","tool_input":{"file_path":"'"$REC"'","edits":[{"old_string":"HEADING","new_string":"placeholder-a","replace_all":true},{"old_string":"placeholder-a\nREQS","new_string":'"$py_content"',"replace_all":false}]},"cwd":"'"$td"'"}'
  printf '%s' "$payload" | env CLAUDE_PROJECT_DIR="$td" /bin/bash "$HOOKS/traceability-matrix-gate.sh" >/dev/null 2>&1
  rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"; report allow "$got" multiedit-mixed-replace_all
}
run_multiedit_mixed

run_raw_payload deny malformed-json-truncated '{"tool_name":"Write","tool_input":{'
run_raw_payload deny malformed-json-non-object '["not","an","object"]'
run_raw_payload deny malformed-json-empty ''

# missing-core: CLAUDE_PLUGIN_ROOT_CORE pointed at a nonexistent path must
# deny (exit 2), not silently allow (core issue-75 fix; the || guard on the
# gate-lib.sh source line must trip here).
run_missing_core() {
  td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"; mkdir -p "$td/docs/issue-7/reports"
  payload="$(printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":%s},"cwd":"%s"}' \
    "$REC" "$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$NO_MATRIX")" "$td")"
  printf '%s' "$payload" | env CLAUDE_PROJECT_DIR="$td" CLAUDE_PLUGIN_ROOT_CORE="$td/no-such-core" /bin/bash "$HOOKS/traceability-matrix-gate.sh" >/dev/null 2>&1
  rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"; report deny "$got" missing-core
}
run_missing_core

# --- item 4/5 (spec-alignment.md): source/downstream_link shape + optional status ---

SHAPE_VALID='# Requirements Record
## Requirements
- REQ-1: something

## Traceability Matrix
| ID | Description | Source | Downstream Link |
| --- | --- | --- | --- |
| REQ-1 | something | src/file.py | abc1234 |
'
run allow shape-valid-path-and-sha "$REC" "$SHAPE_VALID"

SHAPE_FREE_PROSE_SOURCE='# Requirements Record
## Requirements
- REQ-1: something

## Traceability Matrix
| ID | Description | Source | Downstream Link |
| --- | --- | --- | --- |
| REQ-1 | something | some notes about this | abc1234 |
'
run deny shape-free-prose-source "$REC" "$SHAPE_FREE_PROSE_SOURCE"

SHAPE_FREE_PROSE_LINK='# Requirements Record
## Requirements
- REQ-1: something

## Traceability Matrix
| ID | Description | Source | Downstream Link |
| --- | --- | --- | --- |
| REQ-1 | something | src/file.py | some notes about this |
'
run deny shape-free-prose-downstream-link "$REC" "$SHAPE_FREE_PROSE_LINK"

SHAPE_NOT_YET_LINKED='# Requirements Record
## Requirements
- REQ-1: something

## Traceability Matrix
| ID | Description | Source | Downstream Link |
| --- | --- | --- | --- |
| REQ-1 | something | not yet linked | Not Yet Linked |
'
run allow shape-not-yet-linked-placeholder "$REC" "$SHAPE_NOT_YET_LINKED"

STATUS_COLUMN_FILLED='# Requirements Record
## Requirements
- REQ-1: something
- REQ-2: something else

## Traceability Matrix
| ID | Description | Source | Downstream Link | Status |
| --- | --- | --- | --- | --- |
| REQ-1 | something | src/file.py | abc1234 | landed |
| REQ-2 | something else | not yet linked | not yet linked | drafting |
'
run allow status-column-all-filled "$REC" "$STATUS_COLUMN_FILLED"

STATUS_COLUMN_ONE_EMPTY='# Requirements Record
## Requirements
- REQ-1: something
- REQ-2: something else

## Traceability Matrix
| ID | Description | Source | Downstream Link | Status |
| --- | --- | --- | --- | --- |
| REQ-1 | something | src/file.py | abc1234 | landed |
| REQ-2 | something else | not yet linked | not yet linked | |
'
run deny status-column-one-empty "$REC" "$STATUS_COLUMN_ONE_EMPTY"

NO_STATUS_COLUMN='# Requirements Record
## Requirements
- REQ-1: something

## Traceability Matrix
| ID | Description | Source | Downstream Link |
| --- | --- | --- | --- |
| REQ-1 | something | src/file.py | abc1234 |
'
run allow no-status-column-unaffected "$REC" "$NO_STATUS_COLUMN"

printf '\n== %d passed, %d failed ==\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
