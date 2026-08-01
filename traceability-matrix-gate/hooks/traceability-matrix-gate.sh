#!/usr/bin/env bash
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/gate-lib.sh" || { echo "traceability-matrix-gate.sh: cannot source gate-lib.sh" >&2; exit 2; }
gate_trap_fail_closed
# PreToolUse gate (Write|Edit|MultiEdit) — requirements-engineering
# Facet B: traceability matrix.
#
# Target: docs/issue-<n>/reports/requirements-engineering.md — this role's
# deliverable record, per docs/issue-1/proposals/requirements-engineering.md
# (b)(2)/(c).
#
# Requires an actual markdown table (header row + separator row) inside the
# "traceability matrix" section carrying the four fixed columns (ID,
# Description, Source, Downstream Link) as discrete header cells — not a
# substring match against the section's prose (structural upgrade, per
# docs/issue-13/proposals/requirements-engineering-gate-a-plus.md D2) —
# with a row for every REQ-<id> token found anywhere in the record. Fails
# closed on any internal error.
#
# Kill switch: export TRACEABILITY_MATRIX_GATE_OFF=1 (any other value
# stays active, per gate-lib.sh's gate_kill_switch_active)
set -uo pipefail

role="${CLAUDE_ROLE:-requirements-engineering}"

gate_kill_switch_active "${TRACEABILITY_MATRIX_GATE_OFF:-}" || { trap - EXIT; exit 0; }

command -v python3 >/dev/null 2>&1 || gate_deny "$role" "traceability-matrix-gate.sh requires python3, which is not on PATH; denying rather than guessing."

payload="$(cat 2>/dev/null || true)"
[ -n "$payload" ] || gate_deny "$role" "traceability-matrix-gate: empty tool-use payload on stdin; cannot evaluate the traceability-matrix gate."

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
[ -z "$root" ] && gate_deny "$role" "no project root could be determined; failing closed (traceability-matrix check cannot run)."

TG_PAYLOAD="$payload" TG_ROOT="$root" TG_ROLE="$role" \
python3 <<'PY'
import sys as _fc_sys  # fail-closed-on-internal-error
try:
    import importlib.util, json, os, posixpath, re, sys

    role = os.environ.get("TG_ROLE", "requirements-engineering")

    def deny(m):
        sys.stderr.write("%s: refused — %s\n" % (role, m)); sys.exit(2)

    _spec = importlib.util.spec_from_file_location("gate_lib", os.environ["GATE_LIB_PY"])
    gate_lib = importlib.util.module_from_spec(_spec)
    _spec.loader.exec_module(gate_lib)

    raw = os.environ.get("TG_PAYLOAD", "")
    ev = gate_lib.gate_parse_json_or_deny(raw, deny)

    tool = ev.get("tool_name")
    ti = ev.get("tool_input")
    if not isinstance(ti, dict):
        deny("tool_input is missing or not a JSON object; the gate cannot judge a write it cannot parse (traceability matrix).")

    root = posixpath.normpath(os.environ["TG_ROOT"].replace("\\", "/"))
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
        sys.exit(0)  # not this role's traceability-matrix write surface

    abs_path = posixpath.join(root, rel) if rel else root

    current = None
    if os.path.isfile(abs_path):
        try:
            with open(abs_path, encoding="utf-8-sig") as fh:
                current = fh.read(1 << 20)
        except OSError:
            deny("%s exists but cannot be read; failing closed on the traceability matrix." % rel)

    new_text, ok = gate_lib.gate_reconstruct_write(tool, ti, current)
    if not ok:
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
    matrix_heading = None
    for m in headings:
        if m.start() <= start_idx <= m.end():
            matrix_heading = m
            break
    if matrix_heading is None:
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
        section_text = new_text

    # Structural upgrade (D2): require an actual markdown table header row
    # — a "| ... |" line immediately followed by a "| --- | ... |" style
    # separator line — and check the four required columns against that
    # row's own cells, not against the section's prose. Closes the
    # substring hole where e.g. 'id' matched inside 'valid'/'guide'.
    HEADER_LINE_RE = re.compile(r'^[ \t]*\|.*\|[ \t]*$')
    SEP_LINE_RE = re.compile(r'^[ \t]*\|(?:[\s:-]+\|)+[ \t]*$')

    sec_lines = section_text.splitlines()
    header_idx = None
    for idx in range(len(sec_lines) - 1):
        if HEADER_LINE_RE.match(sec_lines[idx]) and SEP_LINE_RE.match(sec_lines[idx + 1]):
            header_idx = idx
            break

    if header_idx is None:
        deny(
            "traceability-matrix section has no markdown table (a header row followed "
            "by a '| --- |'-style separator row). Per %s, the traceability matrix must "
            "be an actual fixed-column table, not prose mentioning the required column "
            "names." % CITE
        )

    header_cells = [c.strip().lower() for c in sec_lines[header_idx].strip().strip('|').split('|')]

    REQUIRED_COLS = (
        ("ID", ("id",)),
        ("Description", ("description", "desc")),
        ("Source", ("source",)),
        ("Downstream Link", ("downstream link", "downstream", "link")),
    )

    def col_present(aliases):
        return any(cell in aliases for cell in header_cells)

    missing_cols = [label for label, needles in REQUIRED_COLS if not col_present(needles)]

    if missing_cols:
        deny(
            "traceability-matrix table header is missing column(s): %s. Per %s, the "
            "table must carry all four columns (ID, Description, Source, Downstream "
            "Link) as actual header cells." % (", ".join(missing_cols), CITE)
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
  echo "${role}: refused — fail-closed: internal error (judge exited $_fc_rc)" >&2
  exit 2
fi
exit "$_fc_rc"
