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
| REQ-1 | something | src | link |
| REQ-2 | something else | src | link |
'

run deny  no-matrix-section     "$REC" "$NO_MATRIX"
run deny  missing-column        "$REC" "$MISSING_COLUMN"
run deny  missing-row-for-id    "$REC" "$MISSING_ROW"
run allow complete-matrix       "$REC" "$COMPLETE_MATRIX"
run allow foreign-path          "docs/issue-7/reports/qa.md" "no matrix here at all"
run allow kill-switch-off       "$REC" "$NO_MATRIX" "TRACEABILITY_MATRIX_GATE_OFF=1"

printf '\n== %d passed, %d failed ==\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
