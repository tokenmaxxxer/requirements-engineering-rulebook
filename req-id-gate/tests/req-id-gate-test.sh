#!/usr/bin/env bash
# req-id-gate's own gate, exercised as a real subprocess.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
HOOKS="$HERE/../hooks"
pass=0; fail=0
report() { if [ "$2" = "$1" ]; then pass=$((pass+1)); printf 'ok     %-28s %s\n' "$3" "$2"; else fail=$((fail+1)); printf 'FAIL   %-28s want=%s got=%s\n' "$3" "$1" "$2"; fi; }

REC=docs/issue-10/reports/requirements-engineering.md

run() { # want name path content [extra_env]
  td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"; mkdir -p "$td/$(dirname "$3")"
  ( set +o pipefail
    printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":%s},"cwd":"%s"}' \
      "$3" "$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$4")" "$td" \
      | env CLAUDE_PROJECT_DIR="$td" ${5:-} /bin/bash "$HOOKS/req-id-gate.sh" >/dev/null 2>&1 )
  rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"; report "$1" "$got" "$2"
}

run deny  no-req-id "$REC" 'This document lists requirements with no identifiers at all.'

run deny  req-id-no-verification "$REC" 'REQ-1: The system shall log in a user.

Just some unrelated prose with no markers of that other kind nearby.'

run allow req-id-with-verification "$REC" 'REQ-1: The system shall log in a user.

Given valid credentials
When the user submits the login form
Then the user is authenticated.'

run allow foreign-path "docs/issue-10/reports/other.md" 'REQ-1: no id needed here since this path is out of scope.'

# edit-unreconstructable: an Edit whose old_string is not found in current file content
run_edit_unreconstructable() {
  td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"; mkdir -p "$td/$(dirname "$REC")"
  printf 'existing content that does not contain the target string\n' > "$td/$REC"
  ( set +o pipefail
    printf '{"tool_name":"Edit","tool_input":{"file_path":"%s","old_string":"this string is not present","new_string":"REQ-1 given when then"},"cwd":"%s"}' \
      "$REC" "$td" \
      | env CLAUDE_PROJECT_DIR="$td" /bin/bash "$HOOKS/req-id-gate.sh" >/dev/null 2>&1 )
  rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"; report deny "$got" edit-unreconstructable
}
run_edit_unreconstructable

run allow kill-switch-off "$REC" 'This document lists requirements with no identifiers at all.' 'REQ_ID_GATE_OFF=1'

printf '\n== %d passed, %d failed ==\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
