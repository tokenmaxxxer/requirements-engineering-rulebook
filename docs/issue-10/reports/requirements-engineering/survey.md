# Current-state survey — requirements-engineering enforcement gap (issue #10)

Phase 1 only. Backs `docs/issue-10/proposals/requirements-engineering-enforcement.md`.
See `docs/issue-10/reports/requirements-engineering/scout-brief.md` for the
prior-art sweep this survey feeds into.

## 1. What this role's adopted methodology currently says

Source: `docs/issue-1/proposals/requirements-engineering.md` (adopted,
per its own Status line, and reflected into `README.md`'s "Doctrine"
section and `requirements-engineering/hooks/directive.sh`'s `PRODUCES`
string).

- **Phase-1 proposal norm**: seven required sections (Problem/scope,
  Survey-basis pointer, Adopted norm+rationale, Rejected alternative,
  Plugin-reflection plan, Verification plan, Status), plus a citation
  discipline (external claim → inline link; judgment call → labeled
  "assumption").
- **Phase-2 deliverable norm**: a single combined record
  (`docs/issue-N/reports/requirements-engineering.md`) containing three
  role-specific sections on top of canon's role-agnostic §20 fields:
  1. Structured requirements doc — ISO/IEC/IEEE 29148-derived skeleton,
     each requirement carrying a unique ID and an explicit verification
     condition (Given/When/Then or equivalent).
  2. Traceability matrix — fixed columns: Requirement ID, Description,
     Source, Downstream Link.
  3. Ambiguity list, resolved — each entry: statement, candidate
     readings, resolution (or explicit "escalated — unresolved").
- **directive.sh** (`requirements-engineering/hooks/directive.sh`) already
  carries this as a one-line `PRODUCES` string (the "PRODUCES summary"
  issue #10 calls out as the current, insufficiently-deepened form):
  `"structured requirements doc, traceability matrix, ambiguity list
  resolved (each requirement: ID + verification condition; matrix: ID +
  description + source + downstream link; ambiguity: statement +
  candidate readings + resolution)"`.

**What is explicitly logged as missing already**: `docs/issue-2/
proposals/canon-reference-conversion.md` (action item 2) and `README.md`
itself both state, in so many words, that this role's own content-level
requirements gate "has no home in canon and is not re-implemented as an
automated gate here" — deferred to "a follow-up issue" if ever wanted.
Issue #10 is that follow-up.

## 2. Current hook wiring (mechanical baseline)

`requirements-engineering/hooks/hooks.json` registers exactly one hook:
`directive.sh` on `SessionStart`. There is no `PreToolUse` entry at all in
this role's own `hooks.json` (core canon's global gates — trailer-gate,
record-fields-gate, handbook-trigger-gate — fire separately via core's
own install, per the issue-2/issue-5 canon-reference conversions, and
check only contract §20's role-agnostic structural fields, never this
role's requirements-doc/matrix/ambiguity content). There is no state file,
no `hooks/tests/` directory, and no gate script of any kind under
`requirements-engineering/hooks/` beyond `directive.sh`.

## 3. The rigor bar: implementation-rulebook's "hook machine"

Read directly from `~/tokenmaxxxer/rulebooks/implementation-rulebook`
(local checkout, prior art per the scout brief). Structurally:

- **`coding/hooks/coding-progress-gate.sh`** (~180 lines): a `PreToolUse`
  gate matched on `Bash` commands containing `git commit`. It determines
  the commit's subject (from staged `docs/issue-<n>/reports/coding.md`
  paths or a `Subject:` trailer in the commit message), reads a sibling
  role's record (`verify.md`) for the same subject, parses inline
  `finding:` blocks for `severity: blocking` + `addressed_to: coding`,
  and refuses the commit unless coding's own record shows a
  `resolved_findings` entry (naming the finder path + a commit sha) *and*
  the finder record's `loop_state` reads `cleared`. This is the sequencing/
  state-tracking mechanism issue #10 points to ("진행 게이트·상태 추적").
- Every gate in that family shares: a `trap __fc EXIT` fail-closed-at-top
  guard (any non-0/non-2 exit is remapped to 2 = deny), a `python3`
  sub-block reading the PreToolUse JSON payload from stdin, path
  resolution rooted at `$CLAUDE_PROJECT_DIR` (or a `git rev-parse
  --show-toplevel` fallback), and a documented kill switch env var.
- **`tests/run-gate-tests.sh`**: one bash file that, per test case, spins
  up a throwaway git repo, feeds a synthetic JSON PreToolUse event on
  stdin to the target gate script as a real subprocess, and asserts the
  exit code (0/2/other) against an expected verdict. No mocking framework;
  gates are executed for real. ~15 cases across 3 gates in that one file.

Sibling `pricing-rulebook/pricing/hooks/methodology-gate.sh` (~230 lines,
detailed in the scout brief) is the closer structural match for THIS
role's actual need: a content-presence gate on the role's own
proposal/record write surface, not a cross-role progress gate. It has no
state-tracking need because pricing's methodology elements are all
checkable within one file at write time — same shape this role's three
`produces` elements have.

## 4. Gap between current state and the rigor bar

| Dimension | implementation-rulebook / pricing-rulebook | requirements-engineering (current) |
|---|---|---|
| Directive granularity | Per-facet requirement text, some inline in gate deny messages, not just a one-line PRODUCES string | One-line `PRODUCES` string in `directive.sh`; deeper structure exists only in `README.md` prose, not machine-checked |
| PreToolUse content gate | Yes — `methodology-gate.sh` / `coding-progress-gate.sh`, fail-closed, path-scoped | None — `hooks.json` has only `SessionStart` |
| State tracking (ordering) | Yes, where the methodology has a real cross-artifact order (verify → coding) | Not yet assessed whether this role's own order (survey → adopted-norm-with-citation → proposal) needs cross-file state, or is checkable within one file (see proposal §2) |
| Gate tests | `tests/run-gate-tests.sh`, real-subprocess, allow+deny per element | None exist for this role |
| Agents/checklists | N/A for pricing (no repeated multi-step procedure beyond the gate); coding has none either beyond the gate itself | This role's phase-1 proposal norm (7 sections) is currently a prose checklist in README.md, not machine-checked, and not a `agents/` file |
| Canon reference discipline | Both sibling gates are role-owned scripts, not vendored canon; canon (`core/hooks/lib/role-directive.sh`, global §20 gates) is sourced/referenced only | Already correctly reference-only per issue-2/issue-5 precedent — this dimension has no gap, and the proposal must preserve it |

## 5. Constraints carried into the proposal

- Canon (`core/hooks/lib/role-directive.sh`, core's global PreToolUse
  gates) must be referenced only, never copied — matches issue-2's own
  precedent (`directive.sh` sources core, does not vendor it) and issue-5's
  stub-check reference-only pattern.
- `write_scope: []` and the `decides`/`hand-off` boundary are unchanged;
  any new gate/agent file lands under `requirements-engineering/` (this
  role's own plugin directory), never under `core/`.
- The adopted-norm source for phase-2 content requirements remains
  `docs/issue-1/proposals/requirements-engineering.md` — this proposal
  does not re-derive or restate that methodology, only proposes how to
  enforce it mechanically.
