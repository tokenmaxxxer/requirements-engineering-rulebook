# Issue-16 phase 2 record — gate A+ final closeout

## What was done

Fixed the three residual code/test defects the 2026-08-01 re-audit found
surviving the issue-13 delivery (commit 4ddc4f6), exactly as approved in
`docs/issue-16/proposals/requirements-engineering-gate-a-plus-closeout.md`,
with one confirmed deviation from that proposal's D11 mechanism (see
below):

- **D9** — `traceability-matrix-gate.sh`'s `col_present` rewritten from
  substring-within-cell matching to whole-cell alias-set matching, so a
  cell literally reading `Resource` no longer satisfies the `Source`
  column requirement.
- **D10** — added a plain-`Edit`-allow case
  (`edit-plain-completes-all-seven`) to
  `proposal-discipline-gate-test.sh`, the one allow-path shape (a bare
  `Edit`, not `Write`/`MultiEdit`) the suite had never exercised.
- **D11** — added a `missing-core` case to all four suites
  (`CLAUDE_PLUGIN_ROOT_CORE` pointed at a nonexistent path, asserting
  deny/exit 2), and fixed the fail-open source line in all four gates.

**Deviation from the proposal's D11 mechanism**: the proposal's adopted
norm called for reordering `set -uo pipefail` ahead of the `.`-source
line. By the time phase 2 opened, the precondition landed
(tokenmaxxxer-core issue #75, closed) with a different, simpler
canon-confirmed fix: an explicit `||` guard on the source line itself
(`. "$path" || { echo "<gate>.sh: cannot source gate-lib.sh" >&2; exit 2; }`),
documented in that repo's `docs/handbooks/gate-house-standard.md` and
enforced by its `compliance-check.sh` (which greps specifically for
`gate-lib\.sh"$` with no trailing `||` on the same line — a `set -uo
pipefail` reorder would not satisfy that detector at all). Issue #16's
own instruction ("공통 항목은 core #75의 확정 가드/규칙을 참조 적용") is to
apply core #75's *confirmed* guard, which is this `||` guard, not the
proposal's pre-landing guess at one. Applied the landed mechanism instead
of the proposal's superseded one; it satisfies the same verification-plan
item 3 (missing-core case denies with exit 2 specifically) by a more
direct route — a failed source now exits 2 immediately, before
`gate_trap_fail_closed`/`set -uo pipefail`/any `gate_kill_switch_active`
call site is ever reached.

Requirement 2 (matcher/tool-coverage parity) and requirement 4
(README/manifest hygiene) were re-confirmed clean per the proposal's
verification-only plan — see Verification below.

## Why

Issue #16's body names three residual defects from the 2026-08-01
re-audit of the issue-13 delivery, plus four requirements (fix all
residuals, matcher/code parity, missing-core-inclusive green suite +
compliance-check record, README/manifest hygiene). Full defect basis in
`docs/issue-16/reports/requirements-engineering/survey.md`.

## Upstream-basis

- `docs/issue-16/proposals/requirements-engineering-gate-a-plus-closeout.md`
  (approved via the `APPROVE issue-16/requirements-engineering` issue
  comment) — the adopted norm this record executes, with the one D11
  mechanism deviation documented above.
- `docs/issue-16/reports/requirements-engineering/survey.md` — the D9-D11
  defect confirmation.
- tokenmaxxxer-core issue #75 (closed) /
  `core/hooks/lib/gate-lib.sh` + `docs/handbooks/gate-house-standard.md`
  in that repo — the landed source-guard canon this delivery applies.

## Requirements addressed (structured requirements doc)

- **REQ-1**: `traceability-matrix-gate`'s column-header check matches a
  required column against a header cell's whole normalized text, not a
  substring anywhere inside it.
  Given a matrix header row with a cell literally `Resource` and no cell
  equal to `Source`,
  When the gate evaluates the write,
  Then it denies — exercised by `d9-resource-not-source` (green); the
  existing `complete-matrix` allow case and `d2-substring-regression`
  deny case (issue-13's own D2 guard) both still pass, confirming the
  rewrite did not reopen the already-fixed section-level substring hole.

- **REQ-2**: `proposal-discipline-gate`'s suite exercises a plain-`Edit`
  allow path, not only `Write`/`MultiEdit`.
  Given a bare `Edit` whose old_string/new_string completes an
  otherwise-six-section proposal fixture (missing only `## Status`) to
  all seven required sections,
  When the gate reconstructs and evaluates the resulting content,
  Then it allows — exercised by `edit-plain-completes-all-seven`
  (green).

- **REQ-3**: All four gates deny, rather than silently allow, when
  `CLAUDE_PLUGIN_ROOT_CORE` points at a nonexistent path and no valid
  relative `../../core` fallback exists either.
  Given a gate invoked with `CLAUDE_PLUGIN_ROOT_CORE` set to a
  nonexistent directory inside a fresh temp project root,
  When the gate's guarded source line fails to source `gate-lib.sh`,
  Then it exits 2 (deny) immediately via the `||` guard, before any
  `gate_kill_switch_active` call site could misread the failure as the
  kill switch being off — exercised by the `missing-core` case in each
  of the four suites, all green.

- **REQ-4**: `hooks.json`'s matcher and each gate's own tool-coverage
  tuple stay in exact agreement.
  Given each plugin's `hooks.json` matcher string and its gate script's
  `tool in (...)` tuple,
  When compared directly,
  Then both list exactly `Write`, `Edit`, `MultiEdit` — confirmed below
  under Verification (requirement was already clean; re-confirmed at
  delivery time per the proposal's verification-only plan).

- **REQ-5**: No README or the repo manifest names a file that does not
  exist, and no old role/plugin name survives in either.
  Given every path named in the top-level README and the four plugin
  READMEs,
  When diffed against `find <plugin-dir> -type f`,
  Then every named path exists and no stale name is present — confirmed
  below under Verification (requirement was already clean; re-confirmed
  at delivery time).

## Traceability Matrix

| ID | Description | Source | Downstream Link |
| --- | --- | --- | --- |
| REQ-1 | whole-cell column-header matching | proposal adopted-norm item 1, defect D9 | traceability-matrix-gate.sh, traceability-matrix-gate-test.sh (verification: given/when/then above) |
| REQ-2 | plain-Edit allow-path test case | proposal adopted-norm item 2, defect D10 | proposal-discipline-gate-test.sh (verification: given/when/then above) |
| REQ-3 | missing-core fail-closed guard, all four gates | proposal adopted-norm item 3, defect D11, core issue-75 | req-id-gate, traceability-matrix-gate, ambiguity-resolution-gate, proposal-discipline-gate hooks + their test suites (verification: given/when/then above) |
| REQ-4 | matcher/tool-coverage parity | proposal adopted-norm item 4, issue requirement 2 | all four hooks.json + gate scripts (verification: given/when/then above) |
| REQ-5 | README/manifest hygiene | proposal adopted-norm item 4, issue requirement 4 | top-level + four plugin READMEs (verification: given/when/then above) |

## Ambiguity

No ambiguities found during this phase. The one open design point (the
D11 mechanism) was resolved by deferring to the landed core-canon
precondition over the proposal's pre-landing guess, per the issue's own
instruction to apply core #75's confirmed rule — documented as a
deviation above, not an unresolved ambiguity.

## Verification

1. Full suite green, `bash tests/run-gate-tests.sh`, all four suites,
   64 cases total (17 + 17 + 15 + 15), including the new `missing-core`
   case in each suite:

   ```
   == req-id-gate/tests/req-id-gate-test.sh ==
   17 passed, 0 failed
   == traceability-matrix-gate/tests/traceability-matrix-gate-test.sh ==
   17 passed, 0 failed
   == ambiguity-resolution-gate/tests/ambiguity-resolution-gate-test.sh ==
   15 passed, 0 failed
   == proposal-discipline-gate/tests/proposal-discipline-gate-test.sh ==
   15 passed, 0 failed
   == all plugin gate suites passed ==
   ```

   `docs/handbooks/gate-tests.md`'s per-suite case counts updated to
   match in this same commit.

2. Core's `compliance-check.sh` run against all four gate hooks
   directories, confirming the `||`-guarded source line satisfies the
   detector's regex (`gate-lib\.sh"$` with no guard = FAIL; guarded = ok)
   and no hand-rolled kill-switch/reconstruct logic was introduced:

   ```
   compliance-check: ok — req-id-gate/hooks/req-id-gate.sh
   compliance-check: ok — ambiguity-resolution-gate/hooks/ambiguity-resolution-gate.sh
   compliance-check: ok — traceability-matrix-gate/hooks/traceability-matrix-gate.sh
   compliance-check: ok — proposal-discipline-gate/hooks/proposal-discipline-gate.sh
   ```

   Exit code 0 for each, no violations.

3. Matcher/code parity (requirement 2), manually re-confirmed: each of
   the four `hooks.json` files carries `"matcher": "Write|Edit|MultiEdit"`
   and each gate script's Python payload carries
   `if tool in ("Write", "Edit", "MultiEdit"):` — identical tool sets in
   both places, all four plugins.

4. README/manifest hygiene (requirement 4), manually re-confirmed: every
   file path named across the top-level README and the four plugin
   READMEs (`README.md`, `req-id-gate/README.md`,
   `ambiguity-resolution-gate/README.md`,
   `traceability-matrix-gate/README.md`,
   `proposal-discipline-gate/README.md`) was diffed against
   `find <plugin-dir> -type f` — no ghost entry, no stale/old role or
   plugin name found in either direction.

## Loop state

loop_state: landed

All four issue-16 requirements and the proposal's five verification-plan
items are satisfied; no further phase-2 work remains open for this issue.

## Open findings

None carried forward. The D11 mechanism deviation (landed core-canon `||`
guard instead of the proposal's pre-landing `set -uo pipefail` reorder
guess) is documented above as a resolved, intentional substitution, not a
deferred item.
