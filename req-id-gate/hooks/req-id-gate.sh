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

    # --- ears_pattern / verification_method: layered spec-alignment checks ---
    # Per docs/issue-19/proposals/spec-alignment.md items 2/3: each REQ-<id>
    # block must ALSO carry a line-anchored `ears_pattern: <value>` marker
    # (spec's six-value enum) whose statement text satisfies that pattern's
    # EARS keyword-order grammar, AND a line-anchored
    # `verification_method: <value>` marker (spec's four-value enum). Both
    # are additional to the Given/When/Then/verification: check above —
    # neither replaces it.
    EARS_MARKER_RE = re.compile(r'^\s*ears_pattern:\s*(\S+)\s*$', re.I)
    VERIFICATION_METHOD_MARKER_RE = re.compile(r'^\s*verification_method:\s*(\S+)\s*$')
    STATEMENT_LINE_RE = re.compile(r'^\s*statement:\s*(.*)$', re.I)

    EARS_VALUES = {
        "ubiquitous", "event-driven", "state-driven",
        "optional-feature", "unwanted-behaviour", "complex",
    }
    VERIFICATION_METHOD_VALUES = {"Inspection", "Analysis", "Demonstration", "Test"}

    # Word-boundary matching only — a plain substring search would let a
    # crafted statement like "The marshall handles it." satisfy "SHALL" via
    # "marSHALL" (warrant-hunt before-landing finding, issue-19).
    def _kw_find(up, kw, start=0):
        m = re.compile(r'\b' + re.escape(kw) + r'\b').search(up, start)
        return m.start() if m else -1

    def _kw_order_ok(text, keywords):
        # True if, case-insensitively, each keyword in `keywords` (in order,
        # as a whole word) can be found with SHALL appearing after the last
        # one, honoring left-to-right ordering (each subsequent search
        # starts after the previous match).
        up = text.upper()
        pos = 0
        for kw in keywords:
            idx = _kw_find(up, kw, pos)
            if idx == -1:
                return False
            pos = idx + len(kw)
        return _kw_find(up, "SHALL", pos) != -1

    def _ears_ok(pattern, text):
        up = text.upper()
        if pattern == "ubiquitous":
            return _kw_find(up, "SHALL") != -1
        if pattern == "event-driven":
            return _kw_order_ok(text, ["WHEN"])
        if pattern == "state-driven":
            return _kw_order_ok(text, ["WHILE"])
        if pattern == "optional-feature":
            return _kw_order_ok(text, ["WHERE"])
        if pattern == "unwanted-behaviour":
            return _kw_order_ok(text, ["IF"])
        if pattern == "complex":
            shall_idx = _kw_find(up, "SHALL")
            if shall_idx == -1:
                return False
            found = 0
            for kw in ("WHEN", "WHILE", "IF", "WHERE"):
                idx = _kw_find(up, kw)
                if idx != -1 and idx < shall_idx:
                    found += 1
            return found >= 2
        return False

    def _find_block(i):
        # contiguous block after the REQ-id line up to next blank line or
        # next REQ-id, capped at NEARBY_LINES, same window style as the
        # verification-condition check above.
        block = [lines[i]]
        for j in range(i + 1, min(i + 1 + NEARBY_LINES, len(lines))):
            nxt = lines[j]
            if nxt.strip() == "" or REQ_RE.search(nxt):
                break
            block.append(nxt)
        return block

    missing_ears = []
    mismatched_ears = []
    missing_vm = []
    invalid_vm = []

    # Find, for each first occurrence line of a REQ-id, its block; but per
    # the "ever satisfied anywhere" style used above, check across ALL
    # occurrences of a given id and consider it satisfied if any occurrence's
    # block carries a valid marker.
    ears_ok_ids = set()
    ears_seen_marker_ids = set()
    ears_bad_reason = {}
    vm_ok_ids = set()
    vm_seen_marker_ids = set()

    for i, line in enumerate(lines):
        ids_on_line = set(REQ_RE.findall(line))
        if not ids_on_line:
            continue
        block = _find_block(i)

        statement_text = None
        for bline in block:
            sm = STATEMENT_LINE_RE.match(bline)
            if sm:
                statement_text = sm.group(1)
                break
        if statement_text is None:
            statement_text = line

        ears_value = None
        for bline in block:
            em = EARS_MARKER_RE.match(bline)
            if em:
                ears_value = em.group(1)
                break
        if ears_value is not None:
            ears_seen_marker_ids.update(ids_on_line)
            norm_value = ears_value.lower()
            if norm_value in EARS_VALUES and _ears_ok(norm_value, statement_text):
                ears_ok_ids.update(ids_on_line)
            else:
                for rid in ids_on_line:
                    ears_bad_reason[rid] = ears_value

        vm_value = None
        for bline in block:
            vmm = VERIFICATION_METHOD_MARKER_RE.match(bline)
            if vmm:
                vm_value = vmm.group(1)
                break
        if vm_value is not None:
            vm_seen_marker_ids.update(ids_on_line)
            if vm_value in VERIFICATION_METHOD_VALUES:
                vm_ok_ids.update(ids_on_line)

    for rid in all_ids_in_order:
        if rid not in ears_ok_ids:
            if rid in ears_seen_marker_ids:
                mismatched_ears.append("%s (ears_pattern=%s)" % (rid, ears_bad_reason.get(rid, "?")))
            else:
                missing_ears.append(rid)
        if rid not in vm_ok_ids:
            if rid in vm_seen_marker_ids:
                invalid_vm.append(rid)
            else:
                missing_vm.append(rid)

    if missing_ears:
        deny(
            "requirements-doc facet: REQ-<id> present without a nearby, line-anchored "
            "`ears_pattern: <value>` marker (one of ubiquitous, event-driven, "
            "state-driven, optional-feature, unwanted-behaviour, complex), within the "
            "same contiguous block window used for the verification condition: %s. Per "
            "docs/issue-19/proposals/spec-alignment.md item 2, every requirement must "
            "declare its EARS pattern." % ", ".join(missing_ears)
        )
    if mismatched_ears:
        deny(
            "requirements-doc facet: REQ-<id> declares an `ears_pattern` whose value is "
            "either not one of the six spec-enum values or whose statement text does not "
            "satisfy that pattern's EARS keyword-order grammar (e.g. event-driven "
            "requires WHEN before SHALL; state-driven requires WHILE before SHALL; "
            "optional-feature requires WHERE before SHALL; unwanted-behaviour requires IF "
            "before SHALL; complex requires at least two of WHEN/WHILE/IF/WHERE before "
            "SHALL; ubiquitous requires SHALL with no such trigger required): %s." % ", ".join(mismatched_ears)
        )
    if missing_vm:
        deny(
            "requirements-doc facet: REQ-<id> present without a nearby, line-anchored "
            "`verification_method: <value>` marker (one of Inspection, Analysis, "
            "Demonstration, Test), within the same contiguous block window used for the "
            "verification condition: %s. Per docs/issue-19/proposals/spec-alignment.md "
            "item 3, every requirement must declare its verification method." % ", ".join(missing_vm)
        )
    if invalid_vm:
        deny(
            "requirements-doc facet: REQ-<id> declares a `verification_method` value that "
            "is not one of the spec's four enum values (Inspection, Analysis, "
            "Demonstration, Test — case-sensitive exact match): %s." % ", ".join(invalid_vm)
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
