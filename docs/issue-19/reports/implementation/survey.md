Subject: issue-19

# Current-state survey

Scope: map each `roles/specs/requirements-engineering.spec.json` field/
vocabulary item onto this rulebook's existing docs/hooks, and identify
gaps with no current home.

Spec source read from:
`/home/jwjung/.claude/plugins/marketplaces/tokenmaxxxer/roles/specs/requirements-engineering.spec.json`
(not present in this repo — external "on-the-record" marketplace spec,
per issue-19 body).

## Spec required_fields vs. rulebook

| Spec field | Type | Rulebook home today | Gap |
|---|---|---|---|
| `statement` | string | README.md Doctrine "Phase-2 deliverable norms" §1 says each requirement has "a testable statement" (prose, not a literal field label); `req-id-gate.sh` requires `REQ-<id>` + nearby verification marker but never checks a `statement` label. | No literal `statement` vocabulary anywhere; concept exists, name doesn't. |
| `ears_pattern` | enum (ubiquitous/event-driven/state-driven/optional-feature/unwanted-behaviour/complex) | **None.** Not mentioned in README, directive.sh, or any of the four gates. | Full gap — no EARS pattern classification or template-grammar check exists. |
| `source` | ref | Traceability matrix Facet B (`traceability-matrix-gate.sh`) already requires a `Source` column, non-empty per row (D9 fix in issue-16 tightened this to whole-cell alias matching). | Present, but no check that the value *resolves* to a real repo path/commit sha/artifact (spec's `reference_resolution` rule) — today any non-empty cell text passes. |
| `verification_method` | enum (Inspection/Analysis/Demonstration/Test) | `req-id-gate.sh` requires a "verification condition" near each `REQ-<id>`, but accepts free-text Given/When/Then or a `verification:` line — no enum constraint. | Concept present (verification condition), enum vocabulary absent. |
| `downstream_link` | ref | Traceability matrix Facet B already requires a `Downstream Link` column (allows explicit "not yet linked" per README). | Present; same resolution gap as `source` (no real-artifact check). |
| `status` | string, not required | Proposal-discipline-gate checks a `status` field, but only on **phase-1 proposals** ("Proposal only / awaiting Approve" — proposal-lifecycle status, not per-requirement status). No per-requirement `status` in the structured requirements doc or traceability matrix today. | Gap for the per-requirement sense; the proposal-lifecycle sense already exists under a different name/target and should not be conflated. |

## Spec `loop_state` vocabulary vs. rulebook

Spec set: `drafting`, `resolving-ambiguity` (progress); `landed`
(terminal); `hypothesis-not-final` (refusal); `source-unresolvable`
(error).

Today: this repo carries no `docs/specs/record-fields-terminal-states.json`
override (confirmed: `find` found none). The phase-2 record
(`docs/issue-N/reports/requirements-engineering.md`) therefore falls
back to core canon's role-agnostic default loop_state vocabulary
(contract v3 s2's generic per-kind list), not this role-specific set.
Nothing in README/directive.sh currently states this role's own
`loop_state` vocabulary at all.

Gap: the exact five-state spec vocabulary has no rulebook-side
declaration or mechanical check today; a record could currently use any
of core's generic states (or an unrelated string) without a role-scoped
refusal.

## Spec `reference_resolution` rule

"statement must match its declared ears_pattern's template grammar
... source and downstream_link must each resolve to a real repo path,
commit sha, or cited artifact — no orphan references."

Rulebook home: none. `traceability-matrix-gate.sh` checks column
presence and non-empty cells only (structural), never grammar-matching
or reference resolution. This is new mechanical territory, not a rename
of an existing check.

## Spec `recomputation` rule

"status must not move past its initial value before verification_method
is populated." Marked `checked_by: TBD` in the spec itself (issue-521
out-of-scope note — a deliberate follow-up, not yet expected upstream).
No rulebook equivalent exists; given the spec's own TBD status, this is
reasonable to leave as a stated gap rather than build ahead of the
upstream spec's own enforcement plan.

## Existing plugin/doc inventory (write set candidates)

- `README.md` — Doctrine section (`## Doctrine`), the four-plugin table,
  Layout section.
- `requirements-engineering/hooks/directive.sh` — `PRODUCES` line (the
  role's stated deliverable-field vocabulary, echoed into every session).
- `req-id-gate/hooks/req-id-gate.sh` (+ its README, its test file) —
  Facet A: REQ-id + verification condition.
- `traceability-matrix-gate/hooks/traceability-matrix-gate.sh` (+ its
  README, its test file) — Facet B: matrix columns.
- `ambiguity-resolution-gate/hooks/ambiguity-resolution-gate.sh` — Facet
  C: ambiguity list. Spec fields don't touch this facet directly; no
  change surveyed as needed here beyond the loop_state vocabulary
  interaction (`resolving-ambiguity` state name already echoes this
  facet's purpose).
- `proposal-discipline-gate/hooks/proposal-discipline-gate.sh` (+ its
  README, its test file) — checks phase-1 proposal's own `status` field
  (Proposal only/awaiting Approve) — distinct target from the spec's
  per-requirement `status`.
- `docs/specs/record-fields-terminal-states.json` — does not exist yet;
  would be the mechanical home for the role-scoped loop_state override
  (core canon's documented override mechanism, per the role-handoff
  contract's stated `record-fields-terminal-states.json` hook).
- `docs/issue-1/proposals/requirements-engineering.md`,
  `docs/issue-10/proposals/requirements-engineering-enforcement.md` —
  prior adopted-norm basis; not part of the write set, cited as prior
  rationale only.

## Alternatives visible from this survey

1. **Overwrite existing field names to match spec exactly** (e.g. rename
   "testable statement" prose to a literal `statement:` field, rename
   "verification condition" wholesale to the four-value enum) vs.
   **layer the spec vocabulary alongside the existing prose** (add
   `statement:`/`ears_pattern:` as new explicit sub-fields, keep the
   existing Given/When/Then verification-condition check and add the
   enum as an additional required token). The user's directive text
   ("strengthening existing content, never deleting methodology")
   argues for the layering option — this is a real fork visible only
   after reading the gates' actual regexes (Given/When/Then is a richer,
   already-enforced concept than the flat 4-value enum; deleting it to
   match the spec exactly would be a regression the issue explicitly
   forbids).
2. **New standalone gate/plugin for ears_pattern + reference_resolution**
   vs. **extend req-id-gate / traceability-matrix-gate in place**. Both
   are plausible given the one-methodology-per-plugin norm already
   documented in README's "Mechanical enforcement" table; the proposal
   must pick and justify one.
