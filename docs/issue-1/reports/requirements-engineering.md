# Deliverable record — requirements-engineering rulebook maturation (issue #1, phase 2)

## What was done

Reflected the Approved `docs/issue-1/proposals/requirements-engineering.md`
into the plugin:

- `requirements-engineering/hooks/directive.sh`: expanded the `PRODUCES`
  string with the required sub-structure for each record field (per-
  requirement ID + verification condition; matrix ID + description +
  source + downstream link; ambiguity statement + candidate readings +
  resolution).
- `README.md`: added a "Doctrine" section carrying the phase-1 proposal
  norms (seven required sections + citation format) and the phase-2
  deliverable norms (structured requirements doc / traceability matrix /
  ambiguity list, each with required sub-fields), plus a manual-
  verification checklist standing in for an automated gate (deferred per
  the proposal's phase-2 scope decision — no follow-up script added in
  this pass).
- This record itself, applying the new phase-2 norms to itself.

No canon script was copied or modified; `core/hooks/lib/role-directive.sh`,
the three role-agnostic gates, and `stub-check.sh` remain referenced only,
per issue-5's precedent (proposal §(d)5).

## Why

Approved by `JiwonJung94` (listed in `docs/specs/approvers.md`) via the
issue-level comment `APPROVE issue-1/requirements-engineering`
(single-account mode, contract v3 s19). The proposal's rationale for each
adopted norm is in `docs/issue-1/proposals/requirements-engineering.md`
section (c) and is not repeated here.

## Upstream basis

- `docs/issue-1/reports/requirements-engineering/survey.md` — current-state
  survey
- `docs/issue-1/reports/requirements-engineering/scout-brief.md` —
  methodology scouting
- `docs/issue-1/proposals/requirements-engineering.md` — the Approved
  proposal this record executes

## Structured requirements doc

### Introduction

- **Purpose**: make this role's `produces` labels (structured requirements
  doc, traceability matrix, ambiguity list resolved) checkable rather than
  decorative, and give future phase-1 proposals under this role a fixed
  shape.
- **Scope**: plugin doctrine content (`directive.sh` PRODUCES string,
  `README.md` Doctrine section) and this record's own compliance with the
  new phase-2 norm. Does not include an automated enforcement script
  (explicitly deferred, see Ambiguity list below).

### Functional requirements

| ID | Statement | Verification condition |
|---|---|---|
| RQ-1 | `directive.sh`'s `PRODUCES` string must name the sub-structure of each required record field inline. | Given `requirements-engineering/hooks/directive.sh`, when the `PRODUCES` variable is read, then it contains the per-requirement/per-matrix-row/per-ambiguity sub-field detail from proposal §(d)1. |
| RQ-2 | `README.md` must document the seven required phase-1 proposal sections. | Given `README.md`, when the Doctrine → "Phase-1 proposal norms" subsection is read, then all seven section names from proposal §(a)2 are present. |
| RQ-3 | `README.md` must document the three required phase-2 deliverable sections and their sub-fields. | Given `README.md`, when the Doctrine → "Phase-2 deliverable norms" subsection is read, then Structured Requirements / Traceability Matrix / Ambiguity List are named, each with the sub-fields from proposal §(b). |
| RQ-4 | A manual-verification checklist must exist for the phase-2 gate, standing in for automation. | Given `README.md`, when the "Manual-verification checklist" subsection is read, then it lists all four content checks from proposal §(d)4 plus the canon-fields-still-pass check. |
| RQ-5 | This record itself must apply the new phase-2 structure (this doc). | Given this file, when inspected, then it contains Structured Requirements, Traceability Matrix, and Ambiguity List sections in addition to contract §20's role-agnostic fields. |

### Non-functional requirements

| ID | Statement | Verification condition |
|---|---|---|
| RQ-6 | No core canon script content may be copied into this rulebook. | Given the diff of this delivery, when scanned, then no file under `core/hooks/` is created or vendored locally — `directive.sh` still sources canon by reference. |
| RQ-7 | Doctrine additions are additive to contract §20's role-agnostic fields, not a replacement. | Given `README.md`'s Doctrine section, when compared to the role-agnostic fields canon's `record-fields-gate.sh` checks, then no role-agnostic field name is redefined or removed. |

## Traceability matrix

| Requirement ID | Requirement Description | Source | Downstream Link |
|---|---|---|---|
| RQ-1 | Expand `PRODUCES` with sub-structure | Proposal §(d)1 | `requirements-engineering/hooks/directive.sh` (this delivery) |
| RQ-2 | Document 7 phase-1 proposal sections | Proposal §(a)2, §(d)2 | `README.md` § Doctrine → Phase-1 proposal norms (this delivery) |
| RQ-3 | Document 3 phase-2 deliverable sections | Proposal §(b), §(d)3 | `README.md` § Doctrine → Phase-2 deliverable norms (this delivery) |
| RQ-4 | Manual-verification checklist | Proposal §(d)4 | `README.md` § Manual-verification checklist (this delivery) |
| RQ-5 | This record applies the new structure | Proposal §(b) | This file, current sections |
| RQ-6 | No canon vendoring | Proposal §(d)5, issue-5 precedent | Not yet linked — holds by omission; no follow-up artifact expected unless a future audit is requested |
| RQ-7 | Doctrine is additive to §20 | Contract v3 §20; proposal §(b)4 | Not yet linked — no automated check exists yet (see Ambiguity list AMB-2) |

## Ambiguity list, resolved

| # | Ambiguous statement | Candidate readings | Resolution | Resolved by |
|---|---|---|---|---|
| AMB-1 | Proposal §(d)1: expand `PRODUCES` inline "or point to a short doctrine doc if the four-argument call cannot hold it." | (a) Expand the `PRODUCES` string in place; (b) fold all detail into `README.md` only. | (a) chosen: `core_role_directive`'s four arguments are shell variables of unrestricted string length (unlike issue-2's `WRITE_SCOPE`/`BOUNDARY CASE` case, which hit a real structural limit), so the string was expanded directly; `README.md` also gets the doctrine detail for discoverability, not as a substitute. | This role, phase 2, by reading `role-directive.sh`'s call signature — no fixed-width constraint found. |
| AMB-2 | Proposal §(d)3: build a new `record-content-check.sh` script "or, if too heavy for phase 2's first pass, a documented manual-verification checklist … with the gate condition deferred to a further follow-up." | (a) Write and wire the new hook script now; (b) ship the documented checklist only, deferring automation. | (b) chosen: the proposal explicitly offers this as the lighter first-pass option, and no existing gate hook fires on `docs/issue-N/proposals/` or role-specific record content today (per proposal §(d)2), so automating in this pass would be new infrastructure beyond what phase 2 was approved to execute. Deferred, not silently dropped — recorded as RQ-7/AMB-2's open item. | This role, phase 2, per proposal §(d)3's stated fallback. |

## Open findings

- **Deferred automation** (AMB-2 / RQ-7): the phase-2 content checklist is
  manual-verification only; no hook enforces it yet. A follow-up issue
  should decide whether to wire a role-owned
  `requirements-engineering/hooks/tests/record-content-check.sh`.
- Carried forward from `docs/issue-2/reports/requirements-engineering.md`
  (not this role's finding to re-resolve): canon's `record-fields-gate.sh`
  remains role-agnostic by design; this doctrine addition is this role's
  own compensating documentation, not a canon change.

loop_state: landed
