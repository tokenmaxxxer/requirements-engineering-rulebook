# Proposal — requirements-engineering phase-1/phase-2 rulebook norms (issue #1)

**Phase 1 only.** Nothing described here has been executed. Phase 2 opens
only after an account listed in `docs/specs/approvers.md` approves this PR
(contract v3 s19), matching the issue-2 and issue-5 precedent. See
`docs/issue-1/reports/requirements-engineering/survey.md` for the
current-state findings and
`docs/issue-1/reports/requirements-engineering/scout-brief.md` for the
methodology survey this proposal is based on.

## (a) Phase 1 제안서(proposal) 규범

Future phase-1 proposals authored under this role must:

1. **Methodology**: ground every adopted norm in an explicit source
   (standard, textbook, or named practitioner convention) plus a stated
   reason it fits this role's `decides` mandate (검증가능·일관·추적
   가능) — no norm may be adopted on unstated preference. This mirrors the
   "no source, no claim" discipline already used by this repo's
   scouting-adjacent skills and by issue-2/issue-5's proposal style.
2. **Required sections**: Problem/scope statement, Survey-basis pointer
   (link to the survey doc under `docs/issue-N/reports/requirements-
   engineering/`), Adopted norm(s) with rationale, Rejected alternative(s)
   with reason, Plugin-reflection plan, Verification plan (how phase 2
   will confirm the norm was actually applied), Status (Proposal
   only / awaiting Approve).
3. **Evidence/citation format**: every claim drawn from an external source
   carries an inline link (as in this repo's scout-brief convention);
   every claim that is this role's own judgment call, not sourced, is
   explicitly labeled "assumption." Proposals inherit the scout brief's
   "Sources:" list convention — if a proposal cites methodology facts not
   already in its scout brief, it must add them there, not assert them
   bare.

## (b) Phase 2 산출물(deliverable) 규범

A phase-2 requirements-engineering deliverable record (landing at
`docs/issue-N/reports/requirements-engineering.md`, or the actual
`CLAUDE_ROLE`-determined path per contract v3 s11 if it differs) must
contain, as sections of the one record (single-artifact convention, since
`write_scope: []` means this role produces one report, not multiple files):

1. **Structured requirements doc** — organized per an ISO/IEC/IEEE
   29148-derived skeleton scoped to what this role actually needs:
   Introduction (purpose/scope), Requirements (each requirement has a
   unique ID, a testable statement, and an explicit verification
   condition — Given/When/Then or equivalent acceptance-criteria form),
   grouped functional vs. non-functional. Full 29148 sections
   (interfaces/compliance/appendixes) are used only if the source material
   actually contains them — this is a scoped derivation, not a mandate to
   pad.
2. **Traceability matrix** — a table with, at minimum, the core columns:
   Requirement ID, Requirement Description, Source (which stakeholder
   input / hypothesis / prior artifact it traces back to), and Downstream
   Link (design/test artifact or explicit "not yet linked" if none exists
   yet — this role hands off before build, so downstream links may be
   forward-pointers rather than completed links). No matrix without unique
   IDs on both ends of every row.
3. **Ambiguity list, resolved** — every ambiguity found during elicitation
   logged with: the ambiguous statement, the candidate readings, the
   resolution chosen (or "escalated — unresolved" if genuinely unresolved,
   which must not silently become a implicit assumption), and who/what
   source resolved it. A record with zero ambiguities found must say so
   explicitly, not omit the section.
4. Contract §20's existing role-agnostic structural fields (what-was-done
   / why / upstream-basis / loop_state / open-findings), enforced by
   canon's `record-fields-gate.sh` — unchanged, additive only.

## (c) 각 채택의 논리적 근거

- **29148-derived skeleton + unique requirement IDs**: chosen over a bare
  prose requirements doc because the scout brief's must-be #1 shows this
  is the only convergence point between the standards tradition (29148)
  and the traceability tradition (RTM tooling) — both require IDed,
  independently verifiable requirements. This directly operationalizes
  the role's stated `decides` value ("요구사항이 검증가능·일관·추적
  가능하게 명세되었는가") rather than restating it as an unenforceable
  slogan, closing the exact gap `docs/issue-2/reports/implementation.md`
  flagged (produces-labels named but never defined).
- **Fixed-column RTM over free-form traceability notes**: scout brief
  must-be #2 — every RTM source surveyed (testing-tool vendors, PM
  tooling, guides) independently converges on the same minimal column set
  (ID, description, source/downstream link, status). Adopting a fixed
  minimum, rather than leaving matrix shape unspecified, is what makes the
  "traceability matrix" produces-label auditable instead of decorative.
- **Given/When/Then-style acceptance criteria per requirement over a bare
  "shall" statement**: scout brief must-be #3 and the INVEST/user-story
  literature — a requirement without an explicit completion condition
  cannot be checked as "met," which defeats 검증가능 (verifiable) directly.
  Chosen over 29148's own more elaborate "Verification" section because
  this role's scope (report-only, hands off before build) does not own
  running the verification, only stating the condition an eventual test
  will check against.
- **Ambiguity as its own logged/resolved section, not folded into the
  requirements doc**: scout brief must-be #4 — the RE literature treats
  ambiguity detection/resolution as a distinct activity from spec-writing.
  Making it a separate, explicitly-required record section (rather than
  letting ambiguities silently vanish into "resolved" requirement text)
  is what makes "ambiguity list resolved" checkable, matching this role's
  produces-label instead of leaving it as an unverified claim.
- **Rejected: adopting a BRD/PRD/MRD/Tech-Spec document-type taxonomy** —
  scout brief's "pattern to skip." Multiple parallel document types would
  require this role to own business-case/KPI content (BRD territory) or
  screen/flow content (this role's own hand-off target,
  `interaction-design`), both outside `write_scope: []` and the explicit
  hand-off arrow. Rejected as scope creep, not as methodologically wrong.
- **Rejected: fully vendoring 29148's complete section set
  (interfaces/compliance/appendixes) unconditionally** — would force
  padding when a requirement set genuinely has no interface or compliance
  dimension, violating this repo's existing anti-padding norm (canon's
  record-fields-gate already rejects boilerplate that doesn't reflect real
  content). Scoped derivation instead: sections are included only when the
  underlying material has content for them.
- **No new document-type-specific citation format invented**: reused this
  repo's existing scout-brief "Sources:"-list + explicit-assumption-label
  convention (see `docs/issue-1/reports/requirements-engineering/scout-
  brief.md` itself) rather than inventing a separate one, since it already
  satisfies "no source, no claim" and keeps phase-1 proposal format
  consistent across roles.

## (d) 플러그인 반영 계획

Phase 2 (after Approve) should make these changes — not made in this PR:

1. **`directive.sh` PRODUCES string**: expand
   `PRODUCES="PRODUCES (required record fields): structured requirements
   doc, traceability matrix, ambiguity list resolved"` to name the
   required sub-structure inline (or point to a short doctrine doc if the
   four-argument `core_role_directive` call cannot hold more text) — e.g.
   append "(each requirement: ID + verification condition; matrix: ID +
   description + source + downstream link; ambiguity: statement +
   candidate readings + resolution)". If `core_role_directive`'s fixed
   four-argument shape can't hold this (same constraint issue-2 hit with
   `WRITE_SCOPE`/`BOUNDARY CASE`), fold the detail into `README.md`'s
   decides/produces block instead, following the issue-2 precedent of
   relocating overflow content there.
2. **Required fields for phase-1 "proposal" records**: a proposal record
   is not gated by canon's `record-fields-gate.sh` (that gate targets
   phase-2 deliverable records per contract §20). This role's own
   proposal norm (section (a) above) — Problem/scope, Survey-basis
   pointer, Adopted norm + rationale, Rejected alternative + reason,
   Plugin-reflection plan, Verification plan, Status — should become a
   documented checklist (e.g. a short doctrine note in `README.md` or a
   `docs/issue-1/` follow-up), referenced by future roles authoring
   proposals here, not enforced by an automated gate in this pass (no
   existing gate hook fires on proposal files under `docs/issue-N/
   proposals/`; adding one is out of scope unless a follow-up issue asks
   for it).
3. **Required fields for phase-2 "deliverable" records**: extend beyond
   canon's role-agnostic §20 fields with role-specific required sections —
   Structured Requirements (with per-requirement ID + verification
   condition), Traceability Matrix (with the four core columns), Ambiguity
   List (resolved or explicitly escalated). This is new role-specific
   content-checking that has no home in core canon (canon's gate is
   role-agnostic by design, per `docs/issue-2/reports/implementation.md`'s
   own open finding) — so it must live in this rulebook, e.g. a
   `requirements-engineering/hooks/tests/record-content-check.sh` (a new
   role-owned script, not a vendored copy of any canon script) wired via
   a `PreToolUse` or verification-time hook, or, if that's too heavy for
   phase 2's first pass, as a documented manual-verification checklist in
   `README.md` with the gate condition deferred to a further follow-up.
4. **Gate conditions to check**:
   - Phase-1 proposal: all seven proposal sections present (name-check);
     Sources/assumption-labeling present in any scouting-basis material it
     references.
   - Phase-2 deliverable: all three role-specific sections present
     (Structured Requirements / Traceability Matrix / Ambiguity List) in
     addition to canon's existing §20 fields; every requirement row in
     the traceability matrix has a non-empty ID and Source column; every
     ambiguity-list entry has a Resolution (or explicit "escalated —
     unresolved") value, never blank.
   - These gate conditions are a **phase-2 design decision**, not
     something this PR wires up — this PR only proposes the schema they'd
     check against. Phase 2 must decide the actual enforcement mechanism
     (new script vs. checklist) and record that decision, per the
     Verification-plan requirement in section (a).
5. **No canon vendoring**: none of the above requires copying core canon
   script content into this rulebook. If phase 2 adds a new role-specific
   check script, it is new role-owned logic (this role's own content
   check, which canon explicitly does not provide), not a copy of
   anything in `core/hooks/`. Existing canon references
   (`stub-check.sh`, `role-directive.sh`, the three role-agnostic gates)
   remain reference-only per issue-5's precedent — untouched by this
   proposal.

## Summary table

| Item | Phase-1 norm | Phase-2 norm |
|---|---|---|
| Requirements doc | N/A | 29148-derived skeleton, unique IDs, per-requirement verification condition |
| Traceability matrix | N/A | Fixed core columns: ID, Description, Source, Downstream Link |
| Ambiguity list | N/A | Statement + candidate readings + resolution (or explicit escalation) per entry |
| Proposal structure | 7 required sections (see (a)) | — |
| Citation format | Sources: list + explicit assumption-labeling | Same, inherited for any deliverable-time sourcing |
| Plugin change | This PR proposes only | `directive.sh`/`README.md` PRODUCES expansion; new role-owned content-check (script or checklist); gate conditions per (d)4 |
| `docs/issue-1/reports/requirements-engineering.md` | Not created yet | Phase-2 deliverable, written only after approval |

## Status

Proposal only. Awaiting Approve from an approver listed in
`docs/specs/approvers.md` before phase 2 (the actual `directive.sh`/
`README.md` edits, new content-check wiring, and verification run) begins.
