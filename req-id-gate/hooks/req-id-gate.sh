#!/usr/bin/env bash
__fc(){ rc=$?; if [ "$rc" != 0 ] && [ "$rc" != 2 ]; then echo "fail-closed: gate aborted (rc=$rc)" >&2; exit 2; fi; }
trap __fc EXIT
# PreToolUse gate (Write|Edit|MultiEdit) — req-id-gate, a single-facet
# plugin for the requirements-engineering role.
#
# Enforces Facet A — structured requirements doc: every requirement in
# the deliverable record must carry a unique REQ-<id> and an explicit
# nearby verification condition (Given/When/Then or "verification:"/
# "verification condition"), per docs/issue-1/proposals/
# requirements-engineering.md (b)(1)/(c).
#
# Target: docs/issue-<n>/reports/requirements-engineering.md (the
# role's deliverable record — this role's own write surface per
# directive.sh; write_scope is report-only for this facet).
#
# Kill switch: export REQ_ID_GATE_OFF=1
set -uo pipefail

role="${CLAUDE_ROLE:-requirements-engineering}"
deny() { echo "${role}: refused — $1" >&2; exit 2; }

case "${REQ_ID_GATE_OFF:-}" in
  ""|0|false|no|off) ;;
  *) exit 0 ;;
esac

command -v python3 >/dev/null 2>&1 || deny "req-id-gate.sh requires python3, which is not on PATH; denying rather than guessing."

payload="$(cat 2>/dev/null || true)"
[ -n "$payload" ] || deny "req-id-gate: empty tool-use payload on stdin; cannot evaluate the requirements-doc facet."

_target="$(printf '%s' "$payload" | python3 -c '
import json,sys
try: e=json.loads(sys.stdin.read())
except Exception: sys.exit(0)
ti=e.get("tool_input") if isinstance(e,dict) else None
if isinstance(ti,dict):
    for k in ("file_path","notebook_path"):
        v=ti.get(k)
        if isinstance(v,str) and v: print(v); break
' 2>/dev/null || true)"

_plausible() { [ -n "$1" ] && [ -d "$1" ] && { [ -e "$1/.git" ] || [ -f "$1/docs/specs/role-handoff-contract.md" ]; }; }
_under() {
  [ -z "$2" ] && return 0
  python3 -c '
import os,posixpath,sys
r,t=sys.argv[1],sys.argv[2]
try: rr=posixpath.normpath(os.path.realpath(r).replace("\\","/"))
except Exception: sys.exit(1)
n=t.replace("\\","/"); a=n if posixpath.isabs(n) else posixpath.join(rr,n)
a=posixpath.normpath(a); real=posixpath.normpath(os.path.realpath(a).replace("\\","/"))
sys.exit(0 if (real==rr or real.startswith(rr+"/")) else 1)
' "$1" "$2"
}

root=""
if [ -n "${CLAUDE_PROJECT_DIR:-}" ] && _plausible "$CLAUDE_PROJECT_DIR" && _under "$CLAUDE_PROJECT_DIR" "$_target"; then
  root="$(cd "$CLAUDE_PROJECT_DIR" 2>/dev/null && pwd -P)"
fi
if [ -z "$root" ]; then
  d="$_target"; [ -n "$d" ] || d="$(pwd -P)"; [ -d "$d" ] || d="$(dirname "$d")"
  root="$(git -C "$d" rev-parse --show-toplevel 2>/dev/null || true)"
fi
[ -z "$root" ] && root="$(git -C "$(pwd -P)" rev-parse --show-toplevel 2>/dev/null || true)"
[ -z "$root" ] && deny "no project root could be determined; failing closed (requirements-doc facet check cannot run)."

RG_PAYLOAD="$payload" RG_ROOT="$root" RG_ROLE="$role" \
python3 <<'PY'
import sys as _fc_sys  # fail-closed-on-internal-error
try:
    import json, os, posixpath, re, sys

    role = os.environ.get("RG_ROLE", "requirements-engineering")

    def deny(m):
        sys.stderr.write("%s: refused — %s\n" % (role, m)); sys.exit(2)

    raw = os.environ.get("RG_PAYLOAD", "")
    try:
        ev = json.loads(raw) if raw else {}
    except ValueError:
        deny("the tool-call payload is not valid JSON; the gate cannot judge the requirements-doc facet on an unparseable write.")
    if not isinstance(ev, dict):
        deny("the tool-call payload is not a JSON object; failing closed on the requirements-doc facet.")

    tool = ev.get("tool_name")
    ti = ev.get("tool_input")
    if not isinstance(ti, dict):
        deny("tool_input is missing or not a JSON object; the gate cannot judge a write it cannot parse (requirements-doc facet).")

    root = posixpath.normpath(os.environ["RG_ROOT"].replace("\\", "/"))
    RECORD_RE = re.compile(r'^docs/issue-[0-9]+/reports/requirements-engineering\.md$')

    def resolve(p):
        n = p.replace("\\", "/")
        a = n if posixpath.isabs(n) else posixpath.join(root, n)
        a = posixpath.normpath(a)
        try:
            return posixpath.normpath(os.path.realpath(a).replace("\\", "/"))
        except OSError:
            return a

    path = None
    if tool in ("Write", "Edit", "MultiEdit"):
        p = ti.get("file_path")
        if isinstance(p, str) and p:
            path = p
    if path is None:
        sys.exit(0)

    r = resolve(path)
    if not r.startswith(root + "/"):
        sys.exit(0)
    rel = r[len(root):].lstrip("/")
    if not RECORD_RE.match(rel):
        sys.exit(0)  # not the deliverable record — not this gate's business

    current = None
    if os.path.isfile(r):
        try:
            with open(r, encoding="utf-8-sig") as fh:
                current = fh.read(1 << 20)
        except OSError:
            deny("%s exists but cannot be read; failing closed on the requirements-doc facet." % rel)

    new_text = None
    if tool == "Write":
        c = ti.get("content")
        if isinstance(c, str):
            new_text = c
    elif tool == "Edit":
        o, n = ti.get("old_string"), ti.get("new_string")
        if isinstance(o, str) and isinstance(n, str) and current is not None and o in current:
            new_text = current.replace(o, n, 1)
    elif tool == "MultiEdit":
        edits = ti.get("edits")
        text = current
        if isinstance(edits, list) and text is not None:
            ok = True
            for e in edits:
                if not isinstance(e, dict):
                    ok = False; break
                o, n = e.get("old_string"), e.get("new_string")
                if not isinstance(o, str) or not isinstance(n, str) or o not in text:
                    ok = False; break
                text = text.replace(o, n, 1)
            if ok:
                new_text = text

    if new_text is None:
        deny(
            "this write targets %s but the gate cannot determine the resulting content "
            "from the tool input (tool=%r). Write the full document with Write, or use an "
            "Edit/MultiEdit whose old_string matches, so the requirements-doc facet can be "
            "checked." % (rel, tool)
        )

    REQ_RE = re.compile(r'\bREQ-[0-9A-Za-z]+(?:-[0-9A-Za-z]+)*\b')
    VERIFY_MARKERS = ("given", "when", "then", "verification:", "verification condition")
    NEARBY_LINES = 8

    if not REQ_RE.search(new_text):
        deny(
            "requirements-doc facet: no REQ-<id> found in the record. Per "
            "docs/issue-1/proposals/requirements-engineering.md (b)(1)/(c), every "
            "requirement must carry a unique REQ-<id>."
        )

    lines = new_text.splitlines()
    unverified_ids = []
    for i, line in enumerate(lines):
        ids_on_line = set(REQ_RE.findall(line))
        if not ids_on_line:
            continue
        window = "\n".join(lines[i:i + 1 + NEARBY_LINES]).lower()
        if not any(marker in window for marker in VERIFY_MARKERS):
            for rid in ids_on_line:
                if rid not in unverified_ids:
                    unverified_ids.append(rid)

    if unverified_ids:
        deny(
            "requirements-doc facet: REQ-<id> present without a nearby verification "
            "condition (Given/When/Then or 'verification:'/'verification condition' "
            "within %d lines): %s. Per docs/issue-1/proposals/requirements-engineering.md "
            "(b)(1)/(c), every requirement must carry an explicit nearby verification "
            "condition." % (NEARBY_LINES, ", ".join(unverified_ids))
        )

    sys.exit(0)
except Exception as _fc_e:  # fail-closed-on-internal-error
    _fc_sys.stderr.write("req-id-gate.sh: fail-closed: internal error: %r\n" % (_fc_e,))
    _fc_sys.exit(2)
PY
_fc_rc=$?  # fail-closed-on-internal-error
if [ "$_fc_rc" -ne 0 ] && [ "$_fc_rc" -ne 2 ]; then
  echo "${role}: refused — fail-closed: internal error (judge exited $_fc_rc)" >&2
  exit 2
fi
exit "$_fc_rc"
