# Current-state survey — requirements-engineering rulebook maturation (issue #1)

Phase 1 survey. No changes executed. Basis for
`docs/issue-1/proposals/requirements-engineering.md`.

## 1. What this rulebook is today

`README.md` and `requirements-engineering/hooks/directive.sh` define this
role's identity (contract v3 role-handoff protocol):

- **decides**: 요구사항이 검증가능·일관·추적 가능하게 명세되었는가
- **use_when**: product 가설이 확정되어 정식 스펙으로 전환할 때
- **produces**: structured requirements doc, traceability matrix, ambiguity
  list resolved
- **write_scope**: `[]` — report-only role, no code/doc write outside the
  record itself
- **hand-off**: 화면/플로우 설계는 → interaction-design

Layout (`README.md` "Layout" section):

- `requirements-engineering/.claude-plugin/plugin.json` — plugin manifest
- `requirements-engineering/hooks/hooks.json` — registers only
  `directive.sh` on `SessionStart`; the trailer/record-fields/
  handbook-trigger gates and warrant-hunter agent are core canon (core
  issue #63/#66) and fire globally per plugin install — no local copies
- `requirements-engineering/hooks/directive.sh` — stub SessionStart
  directive: sources `core/hooks/lib/role-directive.sh`, calls
  `core_role_directive` with this role's four values
- `stub-check.sh` — no local copy (core #69 canon); referenced from the
  core install (`core/hooks/tests/stub-check.sh`), not vendored
- `docs/specs/approvers.md` — Approve-authority allowlist (currently:
  `JiwonJung94`)

This is the full write surface of the role today: `README.md`'s
decides/use_when/produces/write_scope/hand-off block, `directive.sh`'s four
`core_role_directive` argument strings, `hooks.json`'s `SessionStart` entry,
and `plugin.json`'s manifest description. There is **no role-specific
content check** anywhere in this repo or in core canon — canon's
`record-fields-gate.sh` only checks contract §20's role-agnostic structural
fields (what-was-done / why / upstream-basis / loop_state / open-findings),
never this role's own `produces` list (structured requirements doc /
traceability matrix / ambiguity list resolved).

## 2. Prior issues' pattern (precedent for phase 1/2 shape)

Both `docs/issue-2/proposals/canon-reference-conversion.md` and
`docs/issue-5/proposals/stub-check-canon-reference.md` establish the same
phase-1/phase-2 contract shape this issue must follow:

- Phase 1 = survey (`docs/issue-N/reports/.../survey.md` or
  `current-state-survey.md`) + proposal
  (`docs/issue-N/proposals/<name>.md`), no execution, gated on an
  `docs/specs/approvers.md`-listed approver's Approve (contract v3 s19).
- Phase 2 = execute the proposal only after approval; the executing
  session's `CLAUDE_ROLE` determines the actual record path per contract v3
  s11 (board-gate) — e.g. issue-2's phase-2 record landed at
  `docs/issue-2/reports/implementation.md` because that session's role was
  `implementation`, even though the proposal text anticipated
  `docs/issue-2/reports/requirements-engineering.md`.
- Canon scripts are **referenced only, never vendored** — issue-5's PR (#7)
  retired the one remaining vendored copy (`stub-check.sh`) precisely to
  close this loop; the issue-2-era convention of vendoring is now
  superseded. This issue's Phase 2 plugin work must not vendor or copy any
  canon script content — only reference by path/pointer.
- Each phase-1 proposal action item names: what changes, what (if
  anything) replaces it, what config edit (hooks.json / record-fields) is
  needed, and what verification confirms the result.

## 3. The gap this issue exists to close

`docs/issue-2/reports/implementation.md` ("Open findings") explicitly
flagged the gap issue #1 now owns:

> This role's actual content check — a record really contains a structured
> requirements doc, traceability matrix, and resolved ambiguity list — has
> no home in canon's role-agnostic `record-fields-gate.sh` ... Not
> re-implemented in this conversion; a follow-up issue should own it.

Concretely, today:

- **Phase 1 proposal norms**: nothing in this repo specifies what
  methodology, required sections, or evidence/citation format a
  requirements-engineering phase-1 proposal must follow, beyond the
  generic contract v3 s19 phase-1/phase-2 split every role shares. There is
  no requirements-engineering-specific proposal template.
- **Phase 2 deliverable norms**: `produces` names three artifact *labels*
  ("structured requirements doc", "traceability matrix", "ambiguity list
  resolved") but defines none of them — no required internal structure for
  a requirements doc (e.g. functional/non-functional split, priority
  scheme, acceptance-criteria form), no traceability matrix schema
  (requirement ID scheme, source-to-requirement-to-test linkage), no
  ambiguity-list resolution protocol (how an ambiguity is logged, who
  resolves it, what "resolved" means as a record state).
- **Evidence/citation convention**: no requirements-engineering-specific
  citation or evidence-grading convention exists (contrast e.g.
  `tech-feasibility`/`market-recon`-style graded evidence reports elsewhere
  in this ecosystem) — proposals and deliverables currently have no
  required "no source, no claim" discipline of their own beyond whatever
  the author chooses.
- **Gate conditions**: `hooks.json` fires only `SessionStart` →
  `directive.sh`; there is no `PreToolUse`/record-fields extension gate
  that checks for requirements-engineering-specific required sections
  (e.g. "does this record contain a traceability matrix section") the way
  core's role-agnostic gate checks contract §20 structural fields.

## 4. Constraints from the issue text

- warrant-hunter: reference core canon only, no copy (core issue #63) —
  already satisfied by the issue-2 conversion; nothing to re-open here.
- Existing "record 규율·문서화 의무" (record discipline / documentation
  duty) — i.e. contract v3 §20's role-agnostic structural fields enforced
  by canon's `record-fields-gate.sh` — must be **kept**, not replaced. This
  issue's phase-2 plugin work adds a requirements-engineering-specific
  layer on top of, not instead of, that existing discipline.

## 5. What phase 1 (this PR) must produce

Per the issue: a scout brief surveying known requirements-engineering
methodologies/standards/deliverable conventions, then a proposal covering
(a) phase-1 proposal norms, (b) phase-2 deliverable norms, (c) rationale
tying each adopted norm to scouted sources and this gap analysis, (d) a
plugin-reflection plan (directive changes, required record fields for
proposal/deliverable records, gate conditions) — all proposal only; no
`docs/issue-1/reports/requirements-engineering.md` (that is phase-2 and is
out of scope for this PR).
