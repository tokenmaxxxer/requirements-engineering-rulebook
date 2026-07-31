# requirements-engineering-rulebook

Rulebook for the `requirements-engineering` role (contract v3 role-handoff protocol), split off
per `docs/issue-160/proposals/role-taxonomy.md`'s round-4 promotion and
generated as skeleton scaffolding by issue-167.

- **decides**: 요구사항이 검증가능·일관·추적 가능하게 명세되었는가
- **use_when**: product 가설이 확정되어 정식 스펙으로 전환할 때
- **produces**: structured requirements doc, traceability matrix, ambiguity list resolved
  (each requirement: ID + verification condition; matrix: ID + description +
  source + downstream link; ambiguity: statement + candidate readings +
  resolution) — see "Doctrine" below for the full norms this expands
- **write_scope**: []
- **hand-off**: 화면/플로우 설계는 → interaction-design

**BOUNDARY CASE**: if the work in front of you drifts outside `decides`
above, stop and hand off per the arrow — do not silently absorb another
role's scope. Record the hand-off point in this role's record before
opening the next role's session.

## Install

```
claude plugin marketplace add tokenmaxxxer/requirements-engineering-rulebook
claude plugin install requirements-engineering
```

## Layout

- `requirements-engineering/.claude-plugin/plugin.json` — plugin manifest
- `requirements-engineering/hooks/hooks.json` — SessionStart wiring only; the
  trailer/record-fields/handbook-trigger gates and the warrant-hunter agent
  are core canon now (core issue #63/#66) and fire globally per plugin
  install — this rulebook carries no local copies
- `requirements-engineering/hooks/directive.sh` — stub SessionStart role
  directive: sources `core/hooks/lib/role-directive.sh` and calls
  `core_role_directive` with this role's four values
- `stub-check.sh` — no local copy (core #69 canon); drift detector run
  by reference from the core install (`core/hooks/tests/stub-check.sh`)
  against this rulebook's `hooks/` tree, confirming no gate copy has
  regrown locally and that `directive.sh` stays in stub form
- `docs/specs/approvers.md` — Approve-authority allowlist (see below)

This role's `record-fields-gate.sh`-era `produces` check (structured
requirements doc / traceability matrix / ambiguity list, as distinct from
contract §20's role-agnostic structural fields that canon's gate now
checks) has no home in canon and is not re-implemented as an automated
gate here — see `docs/issue-2/reports/requirements-engineering.md` for
that open finding. Per `docs/issue-1/proposals/requirements-engineering.md`
(d)3, the role-specific content is instead enforced as the documented
manual-verification checklist below, deferred to a follow-up issue if an
automated check is ever wanted.

## Doctrine

Adopted by `docs/issue-1/proposals/requirements-engineering.md`
(rationale and rejected alternatives in that proposal's section (c)).

### Phase-1 proposal norms

Every phase-1 proposal authored under this role (landing under
`docs/issue-N/proposals/`) must contain these seven sections:

1. Problem/scope statement
2. Survey-basis pointer (link to `docs/issue-N/reports/requirements-
   engineering/`)
3. Adopted norm(s), each grounded in an explicit source (standard,
   textbook, or named practitioner convention) plus the reason it serves
   this role's `decides` mandate — no norm on unstated preference
4. Rejected alternative(s) with reason
5. Plugin-reflection plan
6. Verification plan — how phase 2 will confirm the norm was actually
   applied
7. Status (Proposal only / awaiting Approve)

Citation format: every externally-sourced claim carries an inline link;
every unsourced judgment call is explicitly labeled "assumption" —
inherited from this repo's scout-brief `Sources:`-list convention.

### Phase-2 deliverable norms

The phase-2 record (`docs/issue-N/reports/requirements-engineering.md`)
is one single artifact (no other files — `write_scope: []`) and must
contain, in addition to contract §20's role-agnostic fields (what-was-
done / why / upstream-basis / loop_state / open-findings, checked by
canon's `record-fields-gate.sh`):

1. **Structured requirements doc** — an ISO/IEC/IEEE 29148-derived
   skeleton scoped to what this role needs: Introduction (purpose/scope),
   Requirements grouped functional vs. non-functional, each with a unique
   ID, a testable statement, and an explicit Given/When/Then-or-equivalent
   verification condition. Full 29148 sections (interfaces/compliance/
   appendixes) are included only when the source material actually has
   content for them — no padding.
2. **Traceability matrix** — a table with at minimum: Requirement ID,
   Requirement Description, Source, Downstream Link (or explicit "not yet
   linked"). No row without a unique, non-empty ID and Source.
3. **Ambiguity list, resolved** — every ambiguity found during elicitation
   logged as: ambiguous statement, candidate readings, resolution chosen
   (or "escalated — unresolved" — never silently folded into an implicit
   assumption), and who/what resolved it. Zero ambiguities found must be
   stated explicitly, not omitted.

### Manual-verification checklist (phase-2 gate, pending automation)

Before a phase-2 record is treated as complete, confirm by inspection:

- [ ] All three role-specific sections present: Structured Requirements /
      Traceability Matrix / Ambiguity List
- [ ] Every requirement has a unique ID and a non-empty verification
      condition
- [ ] Every traceability-matrix row has a non-empty ID and Source column
- [ ] Every ambiguity-list entry has a Resolution value (or explicit
      "escalated — unresolved"), never blank
- [ ] Canon's `record-fields-gate.sh` role-agnostic fields still pass
      (unchanged, additive-only relationship to the above)

No automated script enforces this checklist yet: adding one (role-owned,
never a copy of canon content, e.g. a
`requirements-engineering/hooks/tests/record-content-check.sh`) is left to
a follow-up issue per the proposal's phase-2 scope decision.

This is scaffolding, not a finished rulebook: the doctrine above fills in
the content norms; handoff enforcement and any automated role-specific
progress gate remain open for a follow-up issue.
