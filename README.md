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
- `gate-lib.sh` / `gate-lib.py` — no local copy (core #72 canon, the
  gate-house standard); each of the four gates below sources
  `gate-lib.sh` and loads `gate-lib.py` by reference from the sibling
  core install (`${CLAUDE_PLUGIN_ROOT_CORE:-<plugin>/../../core}`) for
  the fail-closed trap, kill-switch, path-normalization, and
  Write/Edit/MultiEdit reconstruction machinery, instead of
  hand-rolling each — see core's `docs/handbooks/gate-house-standard.md`.
  `compliance-check.sh` — also core canon, no local copy — run by
  reference (`core/hooks/tests/compliance-check.sh <hooks-dir>`) flags
  any gate that hand-rolls the kill-switch/reconstruction shapes instead
  of calling through the library.
- `docs/specs/approvers.md` — Approve-authority allowlist (see below)
- `req-id-gate/`, `traceability-matrix-gate/`, `ambiguity-resolution-gate/`,
  `proposal-discipline-gate/` — four sibling plugins (issue #10), each
  owning exactly one adopted methodology's mechanical enforcement; see
  "Mechanical enforcement" below
- `tests/run-gate-tests.sh` — aggregates all four plugins' own test files

This role's `record-fields-gate.sh`-era `produces` check (structured
requirements doc / traceability matrix / ambiguity list, as distinct from
contract §20's role-agnostic structural fields that canon's gate already
checks) has no home in canon by design (canon is role-agnostic) — see
`docs/issue-2/reports/requirements-engineering.md` for that original open
finding. Per `docs/issue-1/proposals/requirements-engineering.md` (d)3 and
`docs/issue-10/proposals/requirements-engineering-enforcement.md`, the
role-specific content is now enforced by the four plugins below rather
than as a manual checklist.

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
   ID, an explicit `statement:`-labeled testable statement, and an
   explicit Given/When/Then-or-equivalent verification condition. Full
   29148 sections (interfaces/compliance/appendixes) are included only
   when the source material actually has content for them — no padding.
2. **Traceability matrix** — a table with at minimum: Requirement ID,
   Requirement Description, Source, Downstream Link (or explicit "not yet
   linked"), and an optional Status column. No row without a unique,
   non-empty ID and Source.
3. **Ambiguity list, resolved** — every ambiguity found during elicitation
   logged as: ambiguous statement, candidate readings, resolution chosen
   (or "escalated — unresolved" — never silently folded into an implicit
   assumption), and who/what resolved it. Zero ambiguities found must be
   stated explicitly, not omitted.

### Spec-alignment (issue #19) — required deliverable fields

Layered onto the norms above per `docs/issue-19/proposals/spec-alignment.md`,
mapping the realized marketplace spec
(`roles/specs/requirements-engineering.spec.json`) onto this rulebook's
existing methodology without deleting any of it:

- `statement` — the `statement:`-labeled testable statement text required
  by norm 1 above.
- `ears_pattern` — each `REQ-<id>` also carries a line-anchored
  `ears_pattern: <value>` marker, one of `ubiquitous`, `event-driven`,
  `state-driven`, `optional-feature`, `unwanted-behaviour`, `complex`,
  matching the EARS canonical grammar of its statement text (e.g.
  `event-driven` requires `WHEN` before `SHALL`); enforced by
  `req-id-gate`.
- `verification_method` — each `REQ-<id>` also carries a line-anchored
  `verification_method: <value>` marker, one of `Inspection`, `Analysis`,
  `Demonstration`, `Test`, layered alongside (not replacing) the existing
  Given/When/Then/`verification:` condition; enforced by `req-id-gate`.
- `source` / `downstream_link` — the traceability matrix's Source and
  Downstream Link cells, when not the "not yet linked" placeholder, must
  be reference-shaped (a repo-relative path, a 7-40 char hex commit sha,
  or a bracketed/markdown-link citation) — a shape check, not an
  existence check; enforced by `traceability-matrix-gate`.
- `status` — an optional fifth traceability-matrix column; when present,
  every row must have a non-empty Status value; enforced by
  `traceability-matrix-gate`.

### Spec-alignment (issue #19) — loop_state vocabulary

This role's record `loop_state` uses the spec's vocabulary verbatim:

- progress: `drafting`, `resolving-ambiguity`
- terminal: `landed`
- refusal: `hypothesis-not-final`
- error: `source-unresolvable`

No stale contract-generic state and no extra state is intended for this
role's records. **Not mechanically enforced via
`docs/specs/record-fields-terminal-states.json`** — that override file
is keyed by contract §2's fixed canon kinds (`product-record`,
`coding-record`, etc.), each already claimed by an existing role through
core's `ROLE_TO_KIND` map, and core's `record-fields-gate.sh` applies a
matching key globally, not scoped to the declaring role. `requirements-
engineering` is not a canon role in that map, so this role has no key of
its own to add without either being refused outright (an unrecognized
key) or silently overriding another role's terminal-state behavior
(e.g. keying `product-record` would also change the actual `product`
role's loop_state semantics repo-wide). This vocabulary is therefore
doctrine only for now — stated here and in `directive.sh`'s `PRODUCES`
line so a session using this role adopts it by convention, not by gate.
Mechanical enforcement would need core to add `requirements-engineering`
to `ROLE_TO_KIND` first — a core-repo change, out of this rulebook's
write scope. The spec's `recomputation` rule (status-before-
verification_method ordering) is separately left unenforced — out of
scope per `docs/issue-19/proposals/spec-alignment.md`'s Rationale
(upstream marks it `"TBD"`).

### Mechanical enforcement — plugin set (issue #10)

Each content/process methodology above is enforced by its own
self-contained plugin, one methodology per plugin, per
`docs/issue-10/proposals/requirements-engineering-enforcement.md`. All
four are additive on top of (never instead of) canon's role-agnostic
`record-fields-gate.sh`; none checks more than the one facet named:

| Plugin | Fires on | Checks |
|---|---|---|
| `req-id-gate` | `docs/issue-N/reports/requirements-engineering.md` | every `REQ-<id>` has a nearby verification condition (Given/When/Then or `verification:`), a nearby `ears_pattern:` marker matching its statement's EARS grammar, and a nearby `verification_method:` marker; ships `agents/requirements-scout.md` to front-load elicitation → ID → verification-condition ordering |
| `traceability-matrix-gate` | same | a "traceability matrix" section with ID/Description/Source/Downstream Link columns, a row for every `REQ-<id>` in the record, reference-shaped Source/Downstream Link cells, and (when present) a non-empty optional Status column |
| `ambiguity-resolution-gate` | same | an "ambiguity" section that is either explicitly empty ("none found") or has every entry resolved/escalated |
| `proposal-discipline-gate` | `docs/issue-N/proposals/*requirements-engineering*.md` | the seven phase-1 proposal sections above are present |

Each gate is fail-closed, path-scoped to only this role's own write
surfaces, and independently kill-switched
(`REQ_ID_GATE_OFF` / `TRACEABILITY_MATRIX_GATE_OFF` /
`AMBIGUITY_RESOLUTION_GATE_OFF` / `PROPOSAL_DISCIPLINE_GATE_OFF`). Install
alongside the role plugin:

```
claude plugin install req-id-gate
claude plugin install traceability-matrix-gate
claude plugin install ambiguity-resolution-gate
claude plugin install proposal-discipline-gate
```

Run every plugin's gate tests: `bash tests/run-gate-tests.sh` (repo root).

This is no longer scaffolding for the phase-1/phase-2 content norms: the
doctrine above is now machine-checked, not just documented. Handoff
enforcement beyond the four plugins above remains open for a follow-up
issue if one is ever raised.
