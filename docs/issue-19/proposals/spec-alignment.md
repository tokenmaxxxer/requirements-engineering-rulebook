Subject: issue-19

files:
  - README.md
  - requirements-engineering/hooks/directive.sh
  - req-id-gate/hooks/req-id-gate.sh
  - req-id-gate/tests/req-id-gate-test.sh
  - req-id-gate/README.md
  - traceability-matrix-gate/hooks/traceability-matrix-gate.sh
  - traceability-matrix-gate/tests/traceability-matrix-gate-test.sh
  - traceability-matrix-gate/README.md
  - docs/specs/record-fields-terminal-states.json

## Request

Align this rulebook's vocabulary and rules with the realized marketplace
spec `roles/specs/requirements-engineering.spec.json` (on-the-record):
layer the spec's required deliverable fields (`statement`, `ears_pattern`,
`source`, `verification_method`, `downstream_link`, `status`) and its
`loop_state` vocabulary (`drafting`, `hypothesis-not-final`, `landed`,
`resolving-ambiguity`, `source-unresolvable`) onto the rulebook's existing
methodology docs and gates, strengthening what exists rather than
deleting it.

## Constraints

- Never delete existing methodology (Given/When/Then verification
  condition, the four-plugin one-facet-per-plugin structure, the
  phase-1/phase-2 doctrine) — only add/strengthen.
- Every spec required-field name must appear in `docs/` or `README.md`
  after phase 2 (acceptance check 1).
- The role's loop_state vocabulary must match the spec set exactly — no
  stale (contract-generic) or extra states left active for this role's
  record kind (acceptance check 2).
- Any spec field with no natural home must be stated explicitly with
  reasoning, not silently dropped (issue's stated empty-state rule).
- Stay inside the one-methodology-per-plugin norm already documented in
  README's "Mechanical enforcement" table — extend existing gates rather
  than multiply plugins for what is a refinement of already-owned
  facets.

## Rationale

**Layer, don't overwrite** (chosen) **vs. rename existing fields to match
spec labels exactly** (rejected): the survey
(`docs/issue-19/reports/implementation/survey.md`) found the rulebook's
current verification-condition check (Given/When/Then, structurally
anchored, per issue-13's D3 upgrade) is a richer concept than the spec's
flat `verification_method` enum. Renaming it to just the four-value enum
would be a real regression — losing the Given/When/Then structural
anchor issue-13 fought to add — which the issue's own instruction
("never deleting methodology") forbids. Layering adds the enum token
as an additional required marker alongside the existing condition text,
so both checks hold at once.

**Extend `req-id-gate`/`traceability-matrix-gate` in place** (chosen)
**vs. a new standalone plugin per new field** (rejected): `ears_pattern`
and `verification_method` are refinements of Facet A's already-owned
concept (per-requirement verification), and `source`/`downstream_link`
resolution-tightening is a refinement of Facet B's already-owned concept
(matrix columns). README's four-plugin table states "none checks more
than the one facet named" — the fields being added don't introduce a new
facet, they tighten two existing ones. A fifth plugin would fragment one
facet across two gates for no enforcement gain, and the scout brief
confirms the grammar check is a keyword/clause-order structural addition
at the same rigor level as the existing checks, not a new subsystem.

**`status` (per-requirement, spec sense) gets a new home in the
traceability matrix as an optional fifth column** (chosen) **vs.
conflating it with proposal-discipline-gate's existing `status` field**
(rejected): the survey found proposal-discipline-gate's `status` already
means something else (phase-1 proposal lifecycle: "Proposal only /
awaiting Approve"), not per-requirement status. Reusing that name for a
different target would make one field name mean two things in the same
rulebook — confusing rather than aligning. Since the spec marks
`status` `required: false`, it becomes an optional traceability-matrix
column, checked only when present (non-breaking to existing matrices
that omit it).

**Recomputation rule left unenforced** (empty-state, stated per the
issue's rule): the spec's own `recomputation.checked_by` is `"TBD"` with
an explicit issue-521 out-of-scope note deferring per-role enforcement
until real-usage evidence exists upstream. Building rulebook-side
enforcement ahead of the spec's own stated plan would invent a
requirement the spec doesn't yet ask for. Out of scope for phase 2 for
this reason — recorded here, not silently dropped.

## What will be done

1. **`statement` field** — README's Doctrine §"Phase-2 deliverable
   norms" #1 and `req-id-gate.sh`'s docstring get an explicit
   `statement:` label requirement alongside the existing "testable
   statement" prose, so the field name from the spec is literally
   present and checkable, not just implied.
2. **`ears_pattern` field** — new enum requirement layered into
   `req-id-gate.sh`: each `REQ-<id>` block must carry a line-anchored
   `ears_pattern: <value>` marker from the spec's six-value enum
   (`ubiquitous`, `event-driven`, `state-driven`, `optional-feature`,
   `unwanted-behaviour`, `complex`), plus a structural (keyword-based,
   not NLP-parsed — per scout brief) check that the requirement's
   `statement:` text contains that pattern's required keyword(s) in
   order (e.g. `event-driven` requires a line starting `WHEN`, ordered
   before `SHALL`; `state-driven` requires `WHILE` before `SHALL`, etc.,
   per the EARS canonical grammar cited in the scout brief). README's
   doctrine text and `req-id-gate/README.md` document the six values and
   their template grammar. Test file gets one new case per pattern
   (pass) plus a mismatched-keyword case (deny).
3. **`verification_method` enum** — layered onto the existing
   verification-condition check in `req-id-gate.sh`: in addition to the
   current Given/When/Then/`verification:` marker, require a
   `verification_method: <value>` line from the spec's four-value enum
   (`Inspection`, `Analysis`, `Demonstration`, `Test`) within the same
   nearby-lines window. Both checks must pass; neither replaces the
   other.
4. **`source` / `downstream_link` resolution** — `traceability-matrix-
   gate.sh` gains a structural check (already has non-empty-cell
   checking per D9) that a non-"not yet linked" `Source`/`Downstream
   Link` cell value looks like a resolvable reference: a repo-relative
   path, a 7-40 char hex commit sha, or a bracketed/linked citation —
   matching the same reference shapes contract v3 s20 already accepts
   for upstream-basis, so the rulebook doesn't invent a new reference
   grammar. Free text that is neither is denied with a message pointing
   at the spec's own `reference_resolution` rule (README cites it by
   name).
5. **`status` (per-requirement) field** — `traceability-matrix-gate.sh`
   accepts an optional fifth `Status` column; if present, every row must
   have a non-empty value (any string — spec marks the field itself
   type `string`, not enum). README documents it as optional, distinct
   from proposal-discipline-gate's existing proposal-lifecycle `status`.
6. **`loop_state` vocabulary** — new
   `docs/specs/record-fields-terminal-states.json` entry for this role's
   record kind, setting `progress: [drafting, resolving-ambiguity]`,
   `terminal: [landed]`, `refusal: [hypothesis-not-final]`,
   `error: [source-unresolvable]` — the spec's set verbatim, replacing
   reliance on core's generic fallback for this role. README and
   `directive.sh`'s `PRODUCES` line get an explicit loop_state
   vocabulary line so the session-start directive states it up front
   instead of only the JSON file.
7. Update `req-id-gate/README.md` and `traceability-matrix-gate/README.md`
   to describe the added checks; update both plugins' test suites with
   new pass/deny cases per added check; re-run
   `bash tests/run-gate-tests.sh` (verification plan below).

## Out of scope

- The spec's `recomputation` rule (status-before-verification_method
  ordering) — explicitly TBD upstream (see Rationale).
- `ambiguity-resolution-gate.sh` and `proposal-discipline-gate.sh` code
  changes — no spec field maps onto either gate's own facet beyond the
  loop_state vocabulary's `resolving-ambiguity` name, which is a JSON
  config addition, not a change to that gate's logic.
- Any change to the external spec file itself (`roles/specs/
  requirements-engineering.spec.json`) — read-only reference, lives
  outside this repo.
- New plugin creation — rejected in Rationale above.

## How you'll know it worked

- `grep -ri 'statement\|ears_pattern\|source\|verification_method\|downstream_link\|status' docs/ README.md` finds every spec required-field name (acceptance check 1, issue's own check command).
- `docs/specs/record-fields-terminal-states.json`'s entry for this
  role's kind contains exactly `{drafting, resolving-ambiguity, landed,
  hypothesis-not-final, source-unresolvable}` — no stale contract-generic
  state and no extra state (acceptance check 2).
- `bash tests/run-gate-tests.sh` passes, including the new pass/deny
  cases per gate (acceptance check 3 — a test suite is present in this
  repo, so the `pytest`/`unverifiable` fallback in the issue does not
  apply; this repo's suite is bash-based).
- Manual smoke: a requirements record missing `ears_pattern:` or
  `verification_method:` is denied by `req-id-gate.sh`; one with all six
  spec fields present passes; a traceability-matrix row with an
  unresolvable `Source` cell is denied by `traceability-matrix-gate.sh`.
