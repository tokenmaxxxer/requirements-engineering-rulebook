# Proposal — gate A+ final closeout: remaining 2026-08-01 재감사 defects (issue #16)

## Problem / Scope

The 2026-08-01 re-audit of the four merged gate-A+ plugins
(`req-id-gate`, `traceability-matrix-gate`, `ambiguity-resolution-gate`,
`proposal-discipline-gate`, delivered against issue #13 at commit
4ddc4f6) found three residual defects surviving that delivery, listed in
issue #16's body, plus three verification requirements. Scope of this
proposal: design the fix for each residual defect and each verification
requirement. Out of scope: any change to what the four facets check
*for* (semantics fixed by issue #10/#13) or any new facet/gate.

## Survey-Basis

Full defect confirmation in
[`docs/issue-16/reports/requirements-engineering/survey.md`](../reports/requirements-engineering/survey.md).
Three code/test defects (D9-D11) and two already-clean requirements
(matcher/code parity, README/manifest hygiene) confirmed:

- **D9**: `traceability-matrix-gate.sh`'s header-cell column check
  (`col_present`) does substring-within-cell matching (`"source" in
  cell`), so a cell literally reading `Resource` satisfies the Source
  column requirement — the issue's named regression ("Resource가 Source
  만족").
- **D10**: `proposal-discipline-gate`'s test suite (13 cases) has an
  Edit-deny case and a MultiEdit-allow case but no plain-Edit-allow
  case — the issue's "phase1-proposal 스위트 Edit 케이스 부재".
- **D11**: none of the four gates' suites carry the "missing-core" case
  core issue #75 added to its own gate-lib test harness (point
  `CLAUDE_PLUGIN_ROOT_CORE` at a nonexistent path, assert fail-closed
  deny) — issue #16 requirement 3 names this directly.
- Matcher/tool-coverage parity (requirement 2) and README/manifest
  ghost-file/old-name hygiene (requirement 4) are both already clean;
  no fix needed, only a phase-2 re-confirmation step.

## Adopted Norm

1. **D9 fix — whole-cell match, not substring-within-cell, for every
   required column.** Replace `col_present`'s substring test with an
   equality-against-an-alias-set test per cell:

   ```python
   REQUIRED_COLS = (
       ("ID", ("id",)),
       ("Description", ("description", "desc")),
       ("Source", ("source",)),
       ("Downstream Link", ("downstream link", "downstream", "link")),
   )

   def col_present(aliases):
       return any(cell in aliases for cell in header_cells)
   ```

   (`header_cells` are already `.strip().lower()`-normalized at
   construction, so this is a set-membership check on the whole
   normalized cell text, not a scan for a substring inside it.) This is
   exactly this repo's own already-adopted D2 language — "matched as a
   whole cell" (`docs/issue-13/proposals/requirements-engineering-gate-
   a-plus.md`, adopted-norm item 2) — applied literally where the
   original D2 patch stopped one level too shallow (it fixed
   section-text substring, not cell-text substring). `Resource` is not
   in `("source",)` under this check (`"resource" != "source"`); `Valid`
   is not in `("id",)`. `Downstream Link`'s alias set keeps
   `"downstream"` and `"link"` as accepted *whole-cell* alternatives
   (a cell reading just `Downstream` or just `Link` still passes) without
   reopening substring matching — the alias set is enumerated headers,
   not a substring probe.
2. **D10 fix — add one plain-`Edit`-allow case to
   `proposal-discipline-gate-test.sh`.** A single `Edit` whose
   `old_string`/`new_string` transforms an otherwise-six-section fixture
   (missing only `## Status`) into all seven sections by appending the
   status line, asserted **allow** — the mirror image of the existing
   `run_edit_replace_all` (which asserts deny because its edit does not
   complete the document). This closes the gap where every existing
   allow-path case routes through `Write` or `MultiEdit`, never a bare
   `Edit`.
3. **D11 fix — one "missing-core" case per gate suite, reference-adopting
   core issue-75's own shape.** Per gate test file, add a case that runs
   the gate subprocess with `CLAUDE_PLUGIN_ROOT_CORE` pointed at a
   nonexistent path (`"$td/no-such-core"`, the same fixture pattern core
   issue-75's `run-gate-lib-tests.sh` group 7 uses) against otherwise
   non-compliant content, and assert the process **denies** (fails
   closed on the missing library). Because the survey found the current
   preamble order (`source` before `set -uo pipefail`) makes fail-closed
   an accident of bash's own command-not-found exit code rather than the
   gate's own exit-2 contract, this proposal also adopts moving
   `set -uo pipefail` to line 2 (immediately after the shebang, before
   the `.`-source line) in all four gates, so a failed source trips
   `set -e` immediately and the trap set up moments later by
   `gate_trap_fail_closed` is irrelevant to this path (the script has
   already exited before reaching it) — deny happens via the same
   fail-closed mechanism core's own gate-lib preamble uses
   (`docs/handbooks/gate-house-standard.md` line ~99, "no `||` guard on
   the same line" is the fail-open bug that reordering closes), pinning
   the outcome to a real assertion instead of an incidental exit code.
4. **Verification-only steps for the two already-clean requirements**:
   requirement 2 (matcher/code parity) and requirement 4 (README/manifest
   hygiene) get no design change — phase 2 re-runs the same greps this
   survey ran (`grep` each `hooks.json` matcher against each gate's
   Python `tool in (...)` tuple; diff each README's named files against
   `find <plugin-dir> -type f`) as its confirmation evidence, so the
   record shows these were checked, not silently assumed clean because
   the issue #13 delivery already covered them.

## Rejected Alternative

- **Fix D9 by keeping substring matching but adding a negative-lookahead
  denylist (e.g. reject `"source"` if the cell also contains
  `"re"`).** Rejected: this only patches the one collision instance
  actually observed (`Resource`/`Source`) and leaves the general class
  of the bug (any cell whose text happens to contain a required needle
  as a substring) open for the next collision (e.g. a cell reading
  `Outsource` or `Sourced`). Whole-cell alias matching closes the entire
  class in one change, not one instance.
- **Fix D11 by wrapping the `.`-source line in an explicit
  `|| gate_deny ...` instead of reordering `set -uo pipefail`.**
  Rejected: `gate_deny` itself is defined inside `gate-lib.sh` (the very
  file that failed to source), so a `||` guard calling `gate_deny` on
  source failure would itself be undefined at the moment it's needed —
  the same trap this repo's own D1 fix (issue #13) explicitly avoided by
  centralizing fail-closed behavior in the sourced library rather than
  re-deriving it locally per gate. Reordering `set -uo pipefail` needs no
  function from the file that might not exist yet.
- **Skip the D10 Edit-allow case as redundant with the existing
  MultiEdit-allow case.** Rejected: `gate_reconstruct_write` (core
  `gate-lib.py`) has separate code paths for `Edit` (single
  old_string/new_string pair, optional `replace_all`) and `MultiEdit`
  (list of edits applied in sequence) — a regression isolated to the
  single-`Edit` reconstruction path would not be caught by a suite that
  only exercises MultiEdit on the allow side, which is exactly the gap
  issue #16 names.
- **Defer requirement-2/4 re-confirmation to a silent no-op (state
  "already clean" with no phase-2 evidence step).** Rejected: contract
  v3's verification-plan norm (this role's own phase-1 proposal-structure
  requirement, section 6) requires phase 2 to state how a claim was
  confirmed, not merely assert it — even a "no code change needed" branch
  gets a re-run evidence step so the closeout record shows the check
  happened at delivery time, not only at survey time weeks earlier.

## Plugin-Reflection

- **traceability-matrix-gate**: `col_present`/`REQUIRED_COLS` rewritten
  to whole-cell alias matching (D9); preamble reordered for D11
  fail-closed; one missing-core test case added.
- **req-id-gate**: preamble reordered for D11 fail-closed; one
  missing-core test case added; no facet-semantic change (D9/D10 are not
  this gate's defects).
- **ambiguity-resolution-gate**: same as req-id-gate — preamble reorder +
  missing-core case only.
- **proposal-discipline-gate**: preamble reorder + missing-core case
  (shared D11 fix), plus the D10 plain-Edit-allow test case (this gate's
  own suite). This proposal document is itself gated by this plugin's
  unmodified 7-section check, so its own acceptance by that check is live
  evidence the check still functions.
- **`tests/run-gate-tests.sh` / `docs/handbooks/gate-tests.md`**: no
  structural change (same four suites, same aggregation script); the
  per-suite case counts in `gate-tests.md` go up by one each (D11) and
  the proposal-discipline-gate line goes up by one more (D10), updated in
  the same phase-2 commit that adds the cases, per that handbook's
  existing rule.

## Verification Plan

Phase 2 delivers, and must pass before status can move past "proposed":

1. `traceability-matrix-gate`'s own suite gains a regression case: a
   header row with a cell literally `Resource` (and no cell equal to
   `Source`) — must **deny** (D9 regression guard, the exact bug named
   in the issue).
2. `proposal-discipline-gate-test.sh`'s new plain-Edit case — an `Edit`
   completing a six-of-seven-section fixture to all seven — asserted
   **allow** (D10).
3. Each of the four suites' new missing-core case —
   `CLAUDE_PLUGIN_ROOT_CORE` pointed at a nonexistent directory — asserted
   **deny** with exit code 2 specifically (not merely "nonzero"), proving
   the reordered `set -uo pipefail` routes the failure through the gate's
   own fail-closed contract rather than an incidental bash exit code
   (D11).
4. `bash tests/run-gate-tests.sh` green with all four suites' new case
   counts, and `docs/handbooks/gate-tests.md` updated to match
   (currently 16/15/14/13 → 17/16/15/15 after D11's +1 to each and D10's
   +1 more to proposal-discipline-gate).
5. A rulebook-adapted `compliance-check.sh` run (or manual equivalent)
   against this repo's four `hooks/` dirs, confirming no gate hand-rolls
   fail-closed/kill-switch/reconstruct logic post-reorder — the same
   evidence step issue #13's own verification plan required, re-run here
   because the preamble edit touches the exact lines that check guards.
6. Manual re-confirmation, recorded in the phase-2 record: `grep`
   each `hooks.json` matcher against each gate script's `tool in (...)`
   tuple (requirement 2) and diff each of the five READMEs' named files
   against `find <dir> -type f` (requirement 4) — both expected to
   remain clean, evidence attached rather than asserted.

## Status

Proposed — phase 1 only. This document and its survey are committed and
the PR is opened for review; no phase-2 execution (hook edits, test
additions, handbook count updates) happens until an approvers.md account
submits the PR review Approve or the single-account `APPROVE
issue-16/requirements-engineering` issue comment, per contract v3 s19.
