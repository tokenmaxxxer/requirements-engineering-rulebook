# Issue-13 phase 2 record — gate A+ remediation

## What was done

Migrated all four merged enforcement plugins (`req-id-gate`,
`traceability-matrix-gate`, `ambiguity-resolution-gate`,
`proposal-discipline-gate`) to source core's `gate-lib.sh`/`gate-lib.py`
(core issue #72, landed) instead of hand-rolling the fail-closed trap,
kill-switch, path-normalization, and Write/Edit/MultiEdit reconstruction
shapes, exactly as approved in
`docs/issue-13/proposals/requirements-engineering-gate-a-plus.md`. Upgraded
the two facet-specific semantic checks the standard does not itself
prescribe: `traceability-matrix-gate`'s column-header check from substring
to actual markdown-table-header parsing (D2), and `req-id-gate`'s
verification-condition check from an 8-line substring window to a
structurally line-anchored, adjacency-bounded block (D3). Added the mandatory test cases (Edit-`replace_all`,
MultiEdit-mixed-`replace_all`, malformed-JSON x3, kill-switch-unrecognized-
stays-active, absolute-path, `./`-prefixed-path, plus each gate's own
regression guard) to all four suites — 58 cases total, all green. Resynced
all five READMEs (top-level + four plugin READMEs) with the real
kill-switch semantics (issue #72 reversed the default: only a recognized
on-spelling disables; everything else, including a typo, stays active),
the gate-lib reference pattern, and the structural D2/D3 check shapes; the
`find`-diff confirmed no ghost file was named (D8 — none found, see
below).

## Why

The 2026-08-01 code audit (issue #13 body) graded the four gates B+:
column-header check decorated by substring (`'id'` matched inside
`'valid'`), an 8-line window satisfied by stray prose containing "when",
zero Edit/adversarial test cases, and asked for path-matching, fail-closed,
and Edit/MultiEdit/`replace_all` remediation plus a README/reality resync,
gated on core issue #72 (the gate-house standard) landing first so this
role's fix reference-adopts the shared library rather than re-deriving it
locally (the issue's explicit precondition: "자체 재구현 금지").

## Upstream-basis

- `docs/issue-13/proposals/requirements-engineering-gate-a-plus.md`
  (approved via the `APPROVE issue-13/requirements-engineering` issue
  comment) — the adopted norm this record executes.
- `docs/issue-13/reports/requirements-engineering/survey.md` — the D1-D8
  defect survey the proposal is grounded in.
- core issue #72 / `core/hooks/lib/gate-lib.sh` + `gate-lib.py` +
  core's gate-house-standard handbook (landed) — the shared library and
  compliance detector this migration references, never copies.

## Requirements addressed (structured requirements doc)

### Functional

- **REQ-1**: Each of the four gates sources `gate-lib.sh` (bash) and
  loads `gate-lib.py` (Python payload) by reference from the sibling core
  install, replacing its own hand-rolled trap/kill-switch/path-resolve/
  reconstruct logic, with no vendored copy.
  Given a gate script under `<plugin>/hooks/<plugin>-gate.sh`,
  When core's compliance detector is run against this rulebook's own
  directory tree,
  Then every `*-gate.sh` file reports ok (no hand-rolled kill-switch or
  `.replace(...)`-based reconstruction detected) — confirmed below under
  Verification.

- **REQ-2**: The kill-switch on each gate stays active for any value
  other than a recognized on-spelling (1/true/yes/on, case-insensitive),
  including an unrecognized/typo value — reversing the fail-open default
  the audit found (defect D1).
  Given the corresponding off-variable set to an unrecognized value on a
  write to the record,
  When the corresponding gate hook runs,
  Then it denies rather than passing through — exercised by each suite's
  kill-switch-unrecognized case, all green.

- **REQ-3**: traceability-matrix-gate's column-header check requires an
  actual markdown table header row (a pipe-delimited line immediately
  followed by a dash-separator line) with the four required columns as
  discrete header cells, not a substring match against the section's
  prose (defect D2).
  Given a matrix-labeled record section containing the bare word "valid"
  and prose mentioning description/source/downstream but no real table,
  When the gate evaluates the write,
  Then it denies — exercised by the d2-substring-regression case
  (green); a section with an actual complete table still allows
  (complete-matrix, green).

- **REQ-4**: req-id-gate's verification-condition check requires a
  line-anchored Given/When/Then marker (or a verification-labeled line)
  within the contiguous block immediately following the identifier line,
  bounded by the next blank line or next identifier line and capped at 8
  lines — not a substring match anywhere in an unconditioned 8-line
  window (defect D3).
  Given an identifier line followed by unrelated prose that only
  contains the bare word "when" (not line-anchored) within the old
  8-line window,
  When the gate evaluates the write,
  Then it denies — exercised by d3-stray-keyword-not-anchored (green);
  an identifier line immediately followed by a line-anchored
  Given/When/Then block still allows (d3-immediate-anchored-gwt, green).

- **REQ-5**: All four gates correctly reconstruct Edit (honoring
  replace_all) and MultiEdit (honoring each edit's own replace_all
  independently) writes before evaluating their facet, rather than
  always replacing only the first occurrence (defect D6).
  Given an Edit call with replace_all true against a multiply-occurring
  old_string, or a MultiEdit call mixing replace_all true and false
  edits in one call,
  When the gate reconstructs the resulting content,
  Then the reconstruction reflects every occurrence's real fate —
  exercised by each suite's edit-replace_all and
  multiedit-mixed-replace_all cases, all green.

- **REQ-6**: All four gates resolve an absolute file_path and a
  dot-slash-prefixed relative file_path to the same in-scope record path
  a bare relative path already resolves to (defect D5), via the shared
  library's path-normalize helper rather than each gate's own hand-rolled
  resolver.
  Given a write whose file_path is the record's absolute path, or is
  dot-slash-prefixed,
  When the gate evaluates it,
  Then it is treated identically to the relative-path fixture —
  exercised by each suite's absolute-path and dot-prefixed-path cases,
  all green.

- **REQ-7**: All four gates deny, rather than silently pass through, a
  malformed-JSON payload: truncated, non-object top level, or empty.
  Given one of those three payload shapes on stdin,
  When the gate runs,
  Then it denies — exercised by each suite's three malformed-json cases,
  all green.

### Non-functional

- **REQ-8**: The full gate test aggregator exits 0 (all four suites
  green) at delivery.
  Given the full suite is run from the repo root,
  When all 58 cases across the four suites execute,
  Then every case reports ok and the aggregator exits 0 — confirmed
  below under Verification.

## Traceability Matrix

| ID | Description | Source | Downstream Link |
| --- | --- | --- | --- |
| REQ-1 | shared-library reference adoption, all four gates | proposal adopted-norm item 1 | req-id-gate, traceability-matrix-gate, ambiguity-resolution-gate, proposal-discipline-gate hooks (verification: given/when/then repeated verbatim above) |
| REQ-2 | kill-switch unrecognized-value-stays-active | proposal adopted-norm item 1, defect D1 | same four hooks; test case kill-switch-unrecognized in each suite (verification: given/when/then repeated verbatim above) |
| REQ-3 | column-header structural table check | proposal adopted-norm item 2, defect D2 | traceability-matrix-gate hook; test case d2-substring-regression (verification: given/when/then repeated verbatim above) |
| REQ-4 | verification-adjacency structural check | proposal adopted-norm item 3, defect D3 | req-id-gate hook; test cases d3-stray-keyword-not-anchored, d3-immediate-anchored-gwt (verification: given/when/then repeated verbatim above) |
| REQ-5 | Edit/MultiEdit replace_all-honoring reconstruction | proposal adopted-norm item 1, defect D6 | same four hooks; test cases edit-replace_all, multiedit-mixed-replace_all in each suite (verification: given/when/then repeated verbatim above) |
| REQ-6 | absolute and dot-slash-prefixed path normalization | proposal adopted-norm item 1, defect D5 | same four hooks; test cases absolute-path, dot-prefixed-path in each suite (verification: given/when/then repeated verbatim above) |
| REQ-7 | malformed-JSON fail-closed | proposal adopted-norm item 1 | same four hooks; test cases malformed-json-truncated, malformed-json-non-object, malformed-json-empty in each suite (verification: given/when/then repeated verbatim above) |
| REQ-8 | full-suite green at delivery | proposal verification-plan item 2 | tests/run-gate-tests.sh aggregator; see Verification below (verification: given/when/then repeated verbatim above) |

## Ambiguity

No ambiguities found during this phase. The proposal's scope (four
listed defects, no new facet, semantics of what each gate checks for
unchanged) left no open reading to resolve; the one design choice the
proposal itself flagged as a judgment call (the D3 adjacency-window
boundary) was already settled in phase 1 with a rejected-alternative
rationale, not reopened here.

## Verification

1. shared-library migration, structurally confirmed clean — ran core's
   compliance detector against this rulebook's four gate hooks:

   ```
   compliance-check: ok — traceability-matrix-gate/hooks/traceability-matrix-gate.sh
   compliance-check: ok — ambiguity-resolution-gate/hooks/ambiguity-resolution-gate.sh
   compliance-check: ok — proposal-discipline-gate/hooks/proposal-discipline-gate.sh
   compliance-check: ok — req-id-gate/hooks/req-id-gate.sh
   ```

   Exit code 0. No gate flagged for a hand-rolled kill-switch or
   .replace(...)-based reconstruction.

2. `bash tests/run-gate-tests.sh` green, all four suites, 58 cases total
   (16 + 15 + 14 + 13), including every mandatory case class from the
   proposal's verification plan (Edit-replace_all,
   MultiEdit-mixed-replace_all, malformed-JSON x3 per suite,
   kill-switch-unrecognized-stays-active, absolute-path,
   dot-slash-prefixed-path, the D2/D3 regression guards):

   ```
   == req-id-gate/tests/req-id-gate-test.sh ==
   16 passed, 0 failed
   == traceability-matrix-gate/tests/traceability-matrix-gate-test.sh ==
   15 passed, 0 failed
   == ambiguity-resolution-gate/tests/ambiguity-resolution-gate-test.sh ==
   14 passed, 0 failed
   == proposal-discipline-gate/tests/proposal-discipline-gate-test.sh ==
   13 passed, 0 failed
   == all plugin gate suites passed ==
   ```

   `docs/handbooks/gate-tests.md`'s per-suite case counts updated to
   match in this same commit.

3. Manual adversarial spot-check (the exact two repros the issue named),
   both reproduced as deny:
   - traceability-matrix-gate.sh denies a section containing the literal
     substring 'id' inside 'valid' with no real table
     (d2-substring-regression).
   - req-id-gate.sh denies an identifier line followed by a stray
     un-anchored "when" within the old 8-line window
     (d3-stray-keyword-not-anchored).

4. README resync (defect D8) — mechanical find-diff against every path
   the top-level and four plugin READMEs name found no ghost entry (all
   named files/paths exist); the top-level README's Layout section
   gained the shared-library reference-not-copy entries, and all five
   READMEs' kill-switch sections were corrected from the pre-issue-72
   fail-open semantics to the actual fail-active-by-default behavior.

## Loop state

loop_state: landed

All four verification-plan items from
`docs/issue-13/proposals/requirements-engineering-gate-a-plus.md` are
satisfied; no further phase-2 work remains open for this issue.

## Open findings

None carried forward. The proposal's one explicitly-deferred item
(defect D8, README resync) is completed above, not deferred further.
