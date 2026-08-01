# Proposal — gate A+ remediation for the four requirements-engineering plugins (issue #13)

## Problem / scope

The 2026-08-01 code audit (issue #13 body) graded the four merged gate
plugins (`req-id-gate`, `traceability-matrix-gate`, `ambiguity-resolution-gate`,
`proposal-discipline-gate`, all from issue #10 / commit 35fbcf3) at B+ and
listed concrete defects: substring-decorated column-header check (`'id'`
matches `'valid'`), an 8-line verification-condition window satisfied by
stray prose containing "when", zero Edit/adversarial test cases, and asked
for path-matching, fail-closed, and Edit/MultiEdit/`replace_all`
remediation plus a README/reality resync. Scope of this proposal: design
the fix for every listed defect, gated on reference-adopting core's
already-landed gate-house standard (core issue-72) rather than
re-deriving the same fixes locally. Out of scope: any new gate/facet beyond
the four that already exist; changing what the gates check *for*
(semantics of REQ-id/traceability/ambiguity/proposal-structure stay as
issue #10 defined them) — only how rigorously and how safely they check it.

## Survey-basis

Full defect-by-defect confirmation against the merged hook scripts is in
[`docs/issue-13/reports/requirements-engineering/survey.md`](../reports/requirements-engineering/survey.md)
(current-state survey, this phase). Summary of the eight findings (D1-D8)
that drive the fixes below: D1 kill-switch fail-open on unrecognized value
(all 4 gates), D2 substring column-header check, D3 keyword-in-window
verification check, D4 zero Edit/MultiEdit/adversarial test cases, D5 path
normalization currently duplicated 4x by hand, D6 `replace_all` ignored in
all 4 gates' Edit/MultiEdit reconstruction, D7 stderr deny already correct
(no fix needed), D8 README ghost-file audit deferred to phase 2 (mechanical,
does not change this design). Core's `gate-lib.sh`/`gate-lib.py` and
`docs/handbooks/gate-house-standard.md` (issue-72, landed, read in full this
phase) supply the fixed shape for D1, D5, D6, and the mandatory D4 test
groups; this proposal's own design work is limited to D2 and D3, which the
standard does not itself prescribe (they are this role's own semantic
checks, not shapes issue-72 audited).

## Adopted norm

1. **Reference-adopt `core/hooks/lib/gate-lib.sh` + `gate-lib.py` in all
   four gates, never re-derive.** Each gate's bash preamble sources
   `gate-lib.sh` from the sibling core install (the same
   `${CORE_PLUGIN_ROOT}`-relative reference pattern this repo already uses
   for `stub-check.sh`, issue #5/#7 — no vendored copy, so
   `stub-check.sh`/`canon-manifest.txt` continues to catch a drift-copy).
   Concretely, per gate:
   - Replace the hand-rolled `trap __fc` line with `gate_trap_fail_closed`.
   - Replace `case "${X_GATE_OFF:-}" in ""|0|false|no|off) ;; *) exit 0;; esac`
     with `gate_kill_switch_active "${X_GATE_OFF:-}" || { trap - EXIT; exit 0; }`
     — fixes D1 (unrecognized value now stays active, matching the issue's
     "킬스위치 비인식 값=활성" requirement) in one line per gate, no local
     judgment call.
   - Replace the four gates' near-identical `deny()`/exit-2 bash function
     with `gate_deny "$role" "$msg"` / `gate_allow`.
   - In the Python payload, load `gate-lib.py` via the documented
     `importlib.util.spec_from_file_location` snippet and call
     `gate_lib.gate_parse_json_or_deny(raw, deny)` (malformed-JSON deny,
     already correct behavior in these gates but now centrally maintained),
     `gate_lib.gate_normalize_path(root, path)` (replaces each gate's
     private `resolve()` — fixes D5 by removing the 4x-duplicated
     hand-rolled path algebra, covered by the standard's own absolute +
     `./`-prefixed test group), and `gate_lib.gate_reconstruct_write(tool,
     tool_input, current_content)` (replaces each gate's own
     `current.replace(o, n, 1)` — fixes D6, `replace_all` now honored
     per-edit for `Edit` and `MultiEdit`).
   - `gate_bash_write_targets` is available but **not** adopted by this
     proposal — none of the four gates' facets are checkable from a Bash
     command string (they all require the resulting document content,
     which a Bash write does not expose to the gate); noted as a rejected
     alternative below.

2. **Upgrade D2 (traceability-matrix column-header check) from substring to
   structural: markdown-table-header parsing.** Locate the traceability-
   matrix section (unchanged: heading-bounded, as today), then within it
   require an actual markdown table header row — a line matching
   `^\s*\|.*\|\s*$` immediately followed by a separator line matching
   `^\s*\|[\s:-]+\|\s*$` — and check the four required column names
   (ID/Description/Source/Downstream Link, case-insensitive, substring
   *within a cell* still allowed since "Downstream Link" legitimately
   contains "Link") against the **cells of that header row**, split on
   unescaped `|`, each cell trimmed and matched as a whole cell (not
   matched against the full section text). This closes the `'id' in
   'valid'` hole because `'id'` no longer matches against arbitrary section
   prose — it must be a cell of an actual table header row, and a cell
   equal to "valid" or "guide" does not equal (or column-uniquely contain
   as a discrete cell) "id"/"ID". Row-per-REQ-id check (D2's second half)
   is unchanged (already correctly section-scoped, not substring-fragile).

3. **Upgrade D3 (req-id-gate verification-condition check) from
   keyword-in-window to structural adjacency.** Two-part fix:
   - Require the three Given/When/Then markers, when used, to each start
     their own line (`^\s*(given|when|then)\b`, case-insensitive) rather
     than appear anywhere in an 8-line lower-cased blob — this is what
     "structure" means for G/W/T and is exactly the shape every G/W/T
     verification-condition example already in this repo's own record
     files takes (one clause per line). The alternative explicit markers
     (`verification:` / `verification condition`) keep their current
     line-anchored check (`^\s*verification[: ]`), tightened the same way.
   - Narrow the adjacency window from "8 lines forward, unconditionally"
     to "the contiguous block immediately following the REQ-id line, up to
     the next blank line or next REQ-id line, whichever is first,
     capped at 8 lines" — this stops a verification condition ten lines
     away in an unrelated paragraph from satisfying a REQ-id it has no
     structural relationship to, while still tolerating a short prose lead-in
     between the REQ-id line and its G/W/T block (issue #1's own record
     examples put one blank-line-free descriptive line before Given).

4. **Mandatory test additions, per gate, modeled on the standard's own
   six-case group (`docs/handbooks/gate-house-standard.md`, "Standard test
   harness")**, adapted to the four facets:
   - `Edit` with `replace_all: true` against a multiply-occurring
     `old_string` — assert the correct (all-occurrences) reconstruction is
     what the facet check runs against.
   - `MultiEdit` with a mix of `replace_all: true`/`false` edits in one
     call.
   - Malformed JSON (truncated, non-object, empty) — already covered for
     req-id-gate's suite; add to the other three.
   - Kill-switch set to an unrecognized value (e.g. `REQ_ID_GATE_OFF=xyz`)
     — must assert the gate **stays active** (deny), not the prior
     fail-open behavior.
   - Absolute `file_path` reaching the same scope match a relative-path
     fixture already covers, plus a `./`-prefixed variant.
   - D2-specific: a section containing the bare word "valid" (or another
     `'id'`-superstring) with no actual table — must deny (regression
     guard for the exact substring bug named in the issue).
   - D3-specific: a REQ-id line followed, ten lines later after an
     unrelated paragraph, by a Given/When/Then block — must deny (regression
     guard for the exact keyword-in-window bug named in the issue); and a
     REQ-id line followed immediately by a same-line-anchored G/W/T block —
     must allow.
   - `tests/run-gate-tests.sh`'s `SUITES` array and
     `docs/handbooks/gate-tests.md`'s case counts updated in the same
     commit that adds these cases, per that handbook's own existing rule.

5. **README resync (D8), phase 2**: mechanical diff of every file/path
   README.md names against `find . -maxdepth 3 -type f`, remove any
   ghost entry, and document each of the four gates' actual kill-switch
   env-var name and hook-registration path — deferred to phase 2 since it
   is a verification/execution step, not a design decision this proposal
   needs to settle.

## Rejected alternative

- **Re-derive fixed kill-switch/path-normalize/reconstruct logic locally
  instead of sourcing `gate-lib.sh`/`gate-lib.py`.** Rejected: the issue's
  precondition explicitly forbids self-reimplementation ("자체 재구현
  금지") once core issue-72 has landed, and a local re-derivation would
  reintroduce exactly the drift issue-72 was filed to stop (43 rulebooks
  each hand-rolling a slightly different version of the same four shapes).
- **Route D2/D3 semantic upgrades through an LLM-based judge (ask a model
  "is this really Given/When/Then structure?") instead of structural
  regex/parsing.** Rejected: gates run as PreToolUse hooks with no model
  call available in that path in this repo's existing pattern (every gate
  here is a pure bash+python subprocess, no API dependency), and an
  LLM-judge gate would be non-deterministic and untestable by the fixed
  fixture-based harness this proposal extends.
- **Adopt `gate_bash_write_targets` to also catch a `Bash`-tool-driven
  write to a scoped file.** Rejected for this proposal's scope: all four
  facets check document *content* (REQ-id presence, matrix structure,
  ambiguity resolution, proposal sections), which a Bash `command` string
  does not carry — a Bash-tool write would still need to be read back from
  disk to be checked, which is a different design (a PostToolUse gate, not
  PreToolUse) outside issue #13's listed defects. Left as a documented gap,
  not silently dropped.
- **Loosen the D3 adjacency window instead of narrowing it (e.g. keep 8
  lines but require the REQ-id and the marker on the same "paragraph"
  however defined).** Rejected: "paragraph" has no fixed operational
  definition across markdown records already in this repo (some use blank
  lines, some use REQ-id-per-line lists) — the next-blank-line-or-next-REQ-id
  boundary is the one already implicit in every current record example
  surveyed, and is exactly checkable without inventing new prose-parsing.

## Plugin-reflection

- **req-id-gate**: gates go through `gate_trap_fail_closed`/
  `gate_kill_switch_active`/`gate_deny`/`gate_allow`/`gate_parse_json_or_deny`/
  `gate_normalize_path`/`gate_reconstruct_write` (D1, D5, D6 fixed
  identically to the other three gates) plus its own D3 structural
  verification-adjacency upgrade (facet-specific, not shared).
- **traceability-matrix-gate**: same core-lib adoption for D1/D5/D6, plus
  its own D2 structural table-header-parsing upgrade (facet-specific).
- **ambiguity-resolution-gate**: same core-lib adoption for D1/D5/D6; no
  facet-specific semantic defect was named in the issue for this gate, so
  its own ambiguity-section check is unchanged beyond the shared fixes.
- **proposal-discipline-gate**: same core-lib adoption for D1/D5/D6; no
  facet-specific semantic defect was named for this gate either — unchanged
  beyond the shared fixes. (This proposal document is itself gated by this
  plugin's current, unmodified check — the 7-section requirement — so this
  document's own structure is direct evidence the unmodified check still
  functions correctly.)

## Verification plan

Phase 2 delivers, and must pass before status can move past "proposed":

1. Each of the four hooks migrated to source `gate-lib.sh`/`gate-lib.py`,
   with no hand-rolled kill-switch/path-resolve/replace-reconstruct logic
   remaining (i.e., a rulebook-adapted `compliance-check.sh` run, or a
   manual equivalent, against this repo's `hooks-dir`s, comes back clean —
   the same evidence step `gate-house-standard.md`'s migration checklist
   requires).
2. `bash tests/run-gate-tests.sh` green with the new mandatory cases
   included (Edit-`replace_all`, MultiEdit-mixed-`replace_all`,
   malformed-JSON x3 more suites, kill-switch-unrecognized-stays-active x4,
   absolute-path x4, D2-substring-regression, D3-window-regression) —
   `docs/handbooks/gate-tests.md`'s per-suite case counts updated to match.
3. Manual adversarial spot-check: a document containing the literal
   substring `'id'` inside an unrelated word (e.g. "valid") but no real
   table, confirmed denied by `traceability-matrix-gate.sh`; a document
   with a REQ-id line and a stray "when" ten lines later in unrelated
   prose, confirmed denied by `req-id-gate.sh`.
4. README updated to name only files that exist, confirmed by the
   mechanical `find`-diff from D8.

## Status

Proposed — phase 1 only. This document and its survey are committed and the
PR is opened for review; no phase-2 execution (hook edits, test additions,
README resync) happens until an approvers.md account submits the PR review
Approve or the single-account `APPROVE issue-13/requirements-engineering`
issue comment, per contract v3 s19.
