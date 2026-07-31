#!/usr/bin/env bash
__fc(){ rc=$?; if [ "$rc" != 0 ] && [ "$rc" != 2 ]; then echo "fail-closed: gate aborted (rc=$rc)" >&2; exit 2; fi; }
trap __fc EXIT
# PreToolUse gate (Write|Edit|MultiEdit) — requirements-engineering
# Facet B: traceability matrix.
#
# Target: docs/issue-<n>/reports/requirements-engineering.md — this role's
# deliverable record, per docs/issue-1/proposals/requirements-engineering.md
# (b)(2)/(c).
#
# Requires a "traceability matrix" section carrying the four fixed columns
# (ID, Description, Source, Downstream Link) with a row for every REQ-<id>
# token found anywhere in the record. Fails closed on any internal error,
# mirroring pricing's methodology-gate.sh pattern.
#
# Kill switch: export TRACEABILITY_MATRIX_GATE_OFF=1
set -uo pipefail

role="${CLAUDE_ROLE:-requirements-engineering}"
deny() { echo "${role}: refused — $1" >&2; exit 2; }

case "${TRACEABILITY_MATRIX_GATE_OFF:-}" in
  ""|0|false|no|off) ;;
  *) exit 0 ;;
esac

command -v python3 >/dev/null 2>&1 || deny "traceability-matrix-gate.sh requires python3, which is not on PATH; denying rather than guessing."

payload="$(cat 2>/dev/null || true)"
[ -n "$payload" ] || deny "traceability-matrix-gate: empty tool-use payload on stdin; cannot evaluate the traceability-matrix gate."

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
[ -z "$root" ] && deny "no project root could be determined; failing closed (traceability-matrix check cannot run)."

TG_PAYLOAD="$payload" TG_ROOT="$root" \
python3 <<'PY'
import sys as _fc_sys  # fail-closed-on-internal-error
try:
    import json, os, posixpath, re, sys

    def deny(m):
        sys.stderr.write("requirements-engineering: refused — %s\n" % m); sys.exit(2)

    raw = os.environ.get("TG_PAYLOAD", "")
    try:
        ev = json.loads(raw) if raw else {}
    except ValueError:
        deny("the tool-call payload is not valid JSON; the gate cannot judge the traceability matrix on an unparseable write.")
    if not isinstance(ev, dict):
        deny("the tool-call payload is not a JSON object; failing closed on the traceability matrix.")

    tool = ev.get("tool_name")
    ti = ev.get("tool_input")
    if not isinstance(ti, dict):
        deny("tool_input is missing or not a JSON object; the gate cannot judge a write it cannot parse (traceability matrix).")

    root = posixpath.normpath(os.environ["TG_ROOT"].replace("\\", "/"))
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
        sys.exit(0)  # not this role's traceability-matrix write surface

    current = None
    if os.path.isfile(r):
        try:
            with open(r, encoding="utf-8-sig") as fh:
                current = fh.read(1 << 20)
        except OSError:
            deny("%s exists but cannot be read; failing closed on the traceability matrix." % rel)

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
            "Edit/MultiEdit whose old_string matches, so the traceability matrix can be "
            "checked." % (rel, tool)
        )

    low = new_text.lower()

    CITE = "docs/issue-1/proposals/requirements-engineering.md (b)(2)/(c)"

    if "traceability matrix" not in low:
        deny(
            "no 'traceability matrix' section found. Per %s, the record must carry a "
            "traceability matrix (ID, Description, Source, Downstream Link) with a row "
            "for every REQ-<id>." % CITE
        )

    # Locate the matrix section: from the "traceability matrix" heading to
    # the next heading of equal-or-higher level, or end of doc.
    heading_re = re.compile(r'^(#{1,6})[ \t]+.*$', re.M)
    headings = list(heading_re.finditer(new_text))

    start_idx = low.index("traceability matrix")
    # Find the heading line that contains (or precedes and covers) this occurrence.
    matrix_heading = None
    for m in headings:
        if m.start() <= start_idx <= m.end():
            matrix_heading = m
            break
    if matrix_heading is None:
        # "traceability matrix" occurs outside any heading line — fall back
        # to treating the nearest preceding heading (if any) as the section
        # start, else the occurrence itself.
        preceding = [m for m in headings if m.end() <= start_idx]
        matrix_heading = preceding[-1] if preceding else None

    if matrix_heading is not None:
        level = len(matrix_heading.group(1))
        section_start = matrix_heading.start()
        section_end = len(new_text)
        for m in headings:
            if m.start() > matrix_heading.start() and len(m.group(1)) <= level:
                section_end = m.start()
                break
        section_text = new_text[section_start:section_end]
    else:
        # No heading structure at all — treat the whole document as the section.
        section_text = new_text

    section_low = section_text.lower()

    has_id = "id" in section_low
    has_desc = ("description" in section_low) or ("desc" in section_low)
    has_source = "source" in section_low
    has_downstream = "downstream" in section_low

    if not (has_id and has_desc and has_source and has_downstream):
        deny(
            "missing column header(s) — need ID, Description, Source, Downstream Link. "
            "Per %s, the traceability matrix must be a fixed-column table with all four "
            "columns present." % CITE
        )

    req_re = re.compile(r'\bREQ-[0-9A-Za-z-]+\b')
    all_req_ids = set(req_re.findall(new_text))
    matrix_ids = set(req_re.findall(section_text))
    missing = all_req_ids - matrix_ids

    if missing:
        deny(
            "row missing for %s. Per %s, every REQ-<id> in the record must have a row "
            "in the traceability matrix." % (", ".join(sorted(missing)), CITE)
        )

    sys.exit(0)
except Exception as _fc_e:  # fail-closed-on-internal-error
    _fc_sys.stderr.write("traceability-matrix-gate.sh: fail-closed: internal error: %r\n" % (_fc_e,))
    _fc_sys.exit(2)
PY
_fc_rc=$?  # fail-closed-on-internal-error
if [ "$_fc_rc" -ne 0 ] && [ "$_fc_rc" -ne 2 ]; then
  echo "requirements-engineering: refused — fail-closed: internal error (judge exited $_fc_rc)" >&2
  exit 2
fi
exit "$_fc_rc"
