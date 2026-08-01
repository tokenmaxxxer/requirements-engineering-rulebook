#!/usr/bin/env bash
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/gate-lib.sh" || { echo "req-id-gate.sh: cannot source gate-lib.sh" >&2; exit 2; }
gate_trap_fail_closed
# PreToolUse gate (Write|Edit|MultiEdit) — req-id-gate, a single-facet
# plugin for the requirements-engineering role.
#
# Enforces Facet A — structured requirements doc: every requirement in
# the deliverable record must carry a unique REQ-<id> and an explicit
# nearby verification condition (Given/When/Then, each marker starting
# its own line, or a line-anchored "verification:"/"verification
# condition" marker), per docs/issue-1/proposals/
# requirements-engineering.md (b)(1)/(c). Structural (line-anchored,
# next-blank-line-or-next-REQ-id-bounded) rather than substring-in-window,
# per docs/issue-13/proposals/requirements-engineering-gate-a-plus.md (D3).
#
# Target: docs/issue-<n>/reports/requirements-engineering.md (the
# role's deliverable record — this role's own write surface per
# directive.sh; write_scope is report-only for this facet).
#
# Kill switch: export REQ_ID_GATE_OFF=1 (any other value stays active,
# per gate-lib.sh's gate_kill_switch_active)
set -uo pipefail

role="${CLAUDE_ROLE:-requirements-engineering}"

gate_kill_switch_active "${REQ_ID_GATE_OFF:-}" || { trap - EXIT; exit 0; }

command -v python3 >/dev/null 2>&1 || gate_deny "$role" "req-id-gate.sh requires python3, which is not on PATH; denying rather than guessing."

payload="$(cat 2>/dev/null || true)"
[ -n "$payload" ] || gate_deny "$role" "req-id-gate: empty tool-use payload on stdin; cannot evaluate the requirements-doc facet."

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
[ -z "$root" ] && gate_deny "$role" "no project root could be determined; failing closed (requirements-doc facet check cannot run)."

RG_PAYLOAD="$payload" RG_ROOT="$root" RG_ROLE="$role" \
python3 <<'PY'
import sys as _fc_sys  # fail-closed-on-internal-error
try:
    import importlib.util, json, os, posixpath, re, sys

    role = os.environ.get("RG_ROLE", "requirements-engineering")

    def deny(m):
        sys.stderr.write("%s: refused — %s\n" % (role, m)); sys.exit(2)

    _spec = importlib.util.spec_from_file_location("gate_lib", os.environ["GATE_LIB_PY"])
    gate_lib = importlib.util.module_from_spec(_spec)
    _spec.loader.exec_module(gate_lib)

    raw = os.environ.get("RG_PAYLOAD", "")
    ev = gate_lib.gate_parse_json_or_deny(raw, deny)

    tool = ev.get("tool_name")
    ti = ev.get("tool_input")
    if not isinstance(ti, dict):
        deny("tool_input is missing or not a JSON object; the gate cannot judge a write it cannot parse (requirements-doc facet).")

    root = posixpath.normpath(os.environ["RG_ROOT"].replace("\\", "/"))
    RECORD_RE = re.compile(r'^docs/issue-[0-9]+/reports/requirements-engineering\.md$')

    path = None
    if tool in ("Write", "Edit", "MultiEdit"):
        p = ti.get("file_path")
        if isinstance(p, str) and p:
            path = p
    if path is None:
        sys.exit(0)

    rel = gate_lib.gate_normalize_path(root, path)
    if rel is None:
        sys.exit(0)
    if not RECORD_RE.match(rel):
        sys.exit(0)  # not the deliverable record — not this gate's business

    abs_path = posixpath.join(root, rel) if rel else root

    current = None
    if os.path.isfile(abs_path):
        try:
            with open(abs_path, encoding="utf-8-sig") as fh:
                current = fh.read(1 << 20)
        except OSError:
            deny("%s exists but cannot be read; failing closed on the requirements-doc facet." % rel)

    new_text, ok = gate_lib.gate_reconstruct_write(tool, ti, current)
    if not ok:
        deny(
            "this write targets %s but the gate cannot determine the resulting content "
            "from the tool input (tool=%r). Write the full document with Write, or use an "
            "Edit/MultiEdit whose old_string matches, so the requirements-doc facet can be "
            "checked." % (rel, tool)
        )

    REQ_RE = re.compile(r'\bREQ-[0-9A-Za-z]+(?:-[0-9A-Za-z]+)*\b')
    GWT_LINE_RE = re.compile(r'^\s*(given|when|then)\b', re.I)
    VERIFY_LINE_RE = re.compile(r'^\s*verification[: ]', re.I)
    NEARBY_LINES = 8

    if not REQ_RE.search(new_text):
        deny(
            "requirements-doc facet: no REQ-<id> found in the record. Per "
            "docs/issue-1/proposals/requirements-engineering.md (b)(1)/(c), every "
            "requirement must carry a unique REQ-<id>."
        )

    def marker_line(line):
        return bool(GWT_LINE_RE.match(line) or VERIFY_LINE_RE.match(line))

    # A REQ-<id> is satisfied once ANY of its occurrences in the document
    # carries a nearby, structurally anchored verification condition — a
    # later bare re-mention of an already-verified id (e.g. its own row in
    # the traceability matrix, or a citation elsewhere) does not need to
    # re-prove it. Per-line-occurrence-only checking would make a
    # traceability-matrix row (one REQ-<id> per line, by definition with
    # no room for its own Given/When/Then block) permanently unsatisfiable
    # once every marker had to be line-anchored (D3) — a real requirement
    # doc cannot both carry a matrix (facet B) and never re-mention an id.
    lines = new_text.splitlines()
    all_ids_in_order = []
    seen_order = set()
    for m in REQ_RE.finditer(new_text):
        if m.group(0) not in seen_order:
            seen_order.add(m.group(0))
            all_ids_in_order.append(m.group(0))

    ever_verified = set()
    for i, line in enumerate(lines):
        ids_on_line = set(REQ_RE.findall(line))
        if not ids_on_line:
            continue
        verified = marker_line(line)
        if not verified:
            for j in range(i + 1, min(i + 1 + NEARBY_LINES, len(lines))):
                nxt = lines[j]
                if nxt.strip() == "" or REQ_RE.search(nxt):
                    break
                if marker_line(nxt):
                    verified = True
                    break
        if verified:
            ever_verified.update(ids_on_line)

    unverified_ids = [rid for rid in all_ids_in_order if rid not in ever_verified]

    if unverified_ids:
        deny(
            "requirements-doc facet: REQ-<id> present without a nearby, structurally "
            "anchored verification condition (a line starting with Given/When/Then, or "
            "'verification:'/'verification condition', within the contiguous block "
            "following the REQ-id line up to the next blank line or next REQ-id, capped "
            "at %d lines): %s. Per docs/issue-1/proposals/requirements-engineering.md "
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
