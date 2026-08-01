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

run_raw_payload() { # want name payload_json [extra_env]
  td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"; mkdir -p "$td/$(dirname "$REC")"
  ( set +o pipefail
    printf '%s' "$3" | env CLAUDE_PROJECT_DIR="$td" ${4:-} /bin/bash "$HOOKS/req-id-gate.sh" >/dev/null 2>&1 )
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

# kill-switch-unrecognized: a garbage value must NOT disable the gate (stays active)
run deny  kill-switch-unrecognized "$REC" 'This document lists requirements with no identifiers at all.' 'REQ_ID_GATE_OFF=xyz'

# absolute-path: an absolute file_path reaching the same scope a relative fixture already covers
run_absolute_path() {
  td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"; mkdir -p "$td/$(dirname "$REC")"
  ( set +o pipefail
    printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":"no ids here"},"cwd":"%s"}' \
      "$td/$REC" "$td" \
      | env CLAUDE_PROJECT_DIR="$td" /bin/bash "$HOOKS/req-id-gate.sh" >/dev/null 2>&1 )
  rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"; report deny "$got" absolute-path
}
run_absolute_path

# dot-prefixed-path: a "./"-prefixed relative file_path reaching the same scope
run deny  dot-prefixed-path "./$REC" 'no ids here either'

# edit-replace_all: an Edit with replace_all:true against a multiply-occurring old_string
run_edit_replace_all() {
  td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"; mkdir -p "$td/$(dirname "$REC")"
  printf 'REQ-1 needs a marker.\nREQ-1 needs a marker.\n' > "$td/$REC"
  ( set +o pipefail
    printf '{"tool_name":"Edit","tool_input":{"file_path":"%s","old_string":"REQ-1 needs a marker.","new_string":"REQ-1: shall do X\\nGiven valid input\\nWhen action occurs\\nThen it verifies","replace_all":true},"cwd":"%s"}' \
      "$REC" "$td" \
      | env CLAUDE_PROJECT_DIR="$td" /bin/bash "$HOOKS/req-id-gate.sh" >/dev/null 2>&1 )
  rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"; report allow "$got" edit-replace_all-all-occurrences-verified
}
run_edit_replace_all

# multiedit-mixed-replace_all: a MultiEdit call mixing replace_all true/false in one call
run_multiedit_mixed() {
  td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"; mkdir -p "$td/$(dirname "$REC")"
  printf 'PLACEHOLDER PLACEHOLDER\nTAIL\n' > "$td/$REC"
  payload='{"tool_name":"MultiEdit","tool_input":{"file_path":"'"$REC"'","edits":[{"old_string":"PLACEHOLDER","new_string":"REQ-1: shall do X","replace_all":true},{"old_string":"TAIL","new_string":"Given a precondition\nWhen an action occurs\nThen it verifies","replace_all":false}]},"cwd":"'"$td"'"}'
  ( set +o pipefail
    printf '%s' "$payload" | env CLAUDE_PROJECT_DIR="$td" /bin/bash "$HOOKS/req-id-gate.sh" >/dev/null 2>&1 )
  rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"; report allow "$got" multiedit-mixed-replace_all
}
run_multiedit_mixed

# malformed-json: truncated / non-object / empty payloads must all deny
run_raw_payload deny malformed-json-truncated '{"tool_name":"Write","tool_input":{'
run_raw_payload deny malformed-json-non-object '["not","an","object"]'
run_raw_payload deny malformed-json-empty ''

# D3 regression guard: a REQ-id line followed (no blank line, within the old
# 8-line window) by unrelated prose that only contains "when" as a
# substring, never a line-anchored marker — must deny now (the exact
# keyword-in-window bug named in the issue).
run deny  d3-stray-keyword-not-anchored "$REC" 'REQ-2: The system shall log out a user.
This paragraph continues describing behavior in prose.
It keeps going here with more unrelated detail.
And more detail again for padding purposes.
Still padding this out further for the test.
Even more line of prose to reach the window.
Getting close to the edge of the old window now.
Finally mentioning that when this happens nothing verifies it.'

# D3 positive: a REQ-id line immediately followed by a line-anchored
# Given/When/Then block (no blank line) must allow.
run allow d3-immediate-anchored-gwt "$REC" 'REQ-3: The system shall reset a password.
Given a valid reset token
When the user submits a new password
Then the password is updated.'

# missing-core: CLAUDE_PLUGIN_ROOT_CORE pointed at a nonexistent path must
# deny (exit 2), not silently allow (core issue-75 fix; the || guard on the
# gate-lib.sh source line must trip here).
run_missing_core() {
  td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"; mkdir -p "$td/$(dirname "$REC")"
  ( set +o pipefail
    printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":"no ids here"},"cwd":"%s"}' \
      "$REC" "$td" \
      | env CLAUDE_PROJECT_DIR="$td" CLAUDE_PLUGIN_ROOT_CORE="$td/no-such-core" /bin/bash "$HOOKS/req-id-gate.sh" >/dev/null 2>&1 )
  rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"; report deny "$got" missing-core
}
run_missing_core

printf '\n== %d passed, %d failed ==\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
