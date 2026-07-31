# Deliverable record — requirements-engineering enforcement plugin set (issue #10, phase 2)

## What was done

Reflected the Approved (via `APPROVE issue-10/requirements-engineering`)
`docs/issue-10/proposals/requirements-engineering-enforcement.md` into
four new self-contained plugins, per the approver's plugin-set correction:

- `req-id-gate/` — `.claude-plugin/plugin.json`, `hooks/req-id-gate.sh`
  (PreToolUse, fail-closed), `hooks/hooks.json`,
  `tests/req-id-gate-test.sh` (6 cases), `README.md`,
  `agents/requirements-scout.md`.
- `traceability-matrix-gate/` — same shape,
  `tests/traceability-matrix-gate-test.sh` (6 cases).
- `ambiguity-resolution-gate/` — same shape,
  `tests/ambiguity-resolution-gate-test.sh` (6 cases).
- `proposal-discipline-gate/` — same shape,
  `tests/proposal-discipline-gate-test.sh` (5 cases).
- `.claude-plugin/marketplace.json` — four new plugin entries added
  alongside the existing `requirements-engineering` entry.
- `tests/run-gate-tests.sh` — new repo-root harness aggregating all four
  plugins' own test files.
- `README.md` — replaced the "Manual-verification checklist (pending
  automation)" section with "Mechanical enforcement — plugin set
  (issue #10)", documenting each plugin's trigger/check/kill-switch and
  the install/test commands.

No core canon script was copied or modified. Each gate script is new,
role-owned logic, structurally patterned after (never a copy of)
`pricing/hooks/methodology-gate.sh` (a sibling rulebook, not core canon):
fail-closed `trap`, path-scoped regex match against a discovered project
root, Write/Edit/MultiEdit content reconstruction, JSON parsed via
python3, deny-closed on any internal error. Each test harness is
structurally patterned after (never a copy of)
`implementation-rulebook/tests/run-gate-tests.sh`'s `run()` shape
(mktemp'd throwaway git repo, synthetic PreToolUse JSON piped to the gate
script, exit-code assertion). `requirements-engineering/hooks/directive.sh`
is unmodified — it continues to source
`core/hooks/lib/role-directive.sh` by reference only.

## Why

Approved by `JiwonJung94` (listed in `docs/specs/approvers.md`) via the
issue-level comment `APPROVE issue-10/requirements-engineering`
(single-account mode, contract v3 s19), after an interim 요구 정정 comment
rejecting the PR's first-draft single-gate design and requiring instead
one independent, self-completing plugin per adopted methodology
(structural rationale for each plugin split is in the proposal's §0 and
"Rejected alternatives" section, not repeated here).

## Upstream basis

- `docs/issue-10/reports/requirements-engineering/survey.md` — current-state
  survey (no mechanical enforcement existed pre-issue-10)
- `docs/issue-10/reports/requirements-engineering/scout-brief.md` —
  methodology scouting (pricing/implementation-rulebook exemplars)
- `docs/issue-10/proposals/requirements-engineering-enforcement.md` — the
  Approved proposal this record executes
- `docs/issue-1/proposals/requirements-engineering.md` — the unmodified,
  not-re-derived adopted-norm source each gate checks against

## Structured requirements doc

### Introduction

- **Purpose**: make the requirements-engineering role's adopted phase-1
  and phase-2 methodology norms (issue #1) mechanically enforced, not
  merely documented, via one independent plugin per methodology.
- **Scope**: the four new plugin directories, the marketplace
  registration, the aggregate test harness, and this record's own
  compliance with its own new `req-id-gate` /
  `traceability-matrix-gate` / `ambiguity-resolution-gate` checks. Does
  not include cross-plugin state tracking (explicitly rejected in the
  proposal — no genuine cross-plugin ordering constraint exists).

### Functional requirements

| ID | Statement | Verification condition |
|---|---|---|
| REQ-1 | `req-id-gate` must deny a phase-2 record write containing a `REQ-<id>` with no nearby verification condition, and allow one where every ID has one. | Given `req-id-gate/hooks/req-id-gate.sh`, when run against a synthetic record with a bare `REQ-x` line and separately against one with a `REQ-x` line followed by a `Given/When/Then` block, then the gate denies the first and allows the second (verified by `req-id-gate/tests/req-id-gate-test.sh`'s `req-id-no-verification` / `req-id-with-verification` cases, both passing). |
| REQ-2 | `traceability-matrix-gate` must deny a record whose traceability-matrix section is missing a required column or missing a row for a `REQ-<id>` that appears elsewhere in the record, and allow a complete matrix. | Given the gate script, when run against a matrix missing the Source column and separately a matrix missing a row for an ID used in the requirements table, then both are denied; a matrix with all four columns and all IDs covered is allowed (verified by `traceability-matrix-gate/tests/traceability-matrix-gate-test.sh`'s `missing-column` / `missing-row-for-id` / `complete-matrix` cases, all passing). |
| REQ-3 | `ambiguity-resolution-gate` must deny a record with an ambiguity heading but no explicit "none found" and no resolved/escalated entry, and allow either an explicit-empty or a resolved ambiguity section. | Given the gate script, when run against a doc with only an "## Ambiguity" heading and separately against one with "resolution:" text, then the first is denied and the second is allowed (verified by `ambiguity-resolution-gate/tests/ambiguity-resolution-gate-test.sh`'s `heading-only-no-resolution` / `resolved-entry-present` cases, both passing). |
| REQ-4 | `proposal-discipline-gate` must deny a phase-1 proposal missing any of the 7 required sections and allow one with all 7 present. | Given the gate script, when run against a proposal body missing a "Status" section and separately against one with all 7 section markers present, then the first is denied and the second is allowed (verified by `proposal-discipline-gate/tests/proposal-discipline-gate-test.sh`'s `missing-status` / `all-seven-sections` cases, both passing). |
| REQ-5 | Each of the four plugins must be independently kill-switchable and fail closed on an unparseable write. | Given each gate script, when its own `<NAME>_GATE_OFF=1` env var is set with content that would otherwise deny, then it exits 0; when an `Edit`'s `old_string` does not match current file content, then `req-id-gate` denies rather than guessing (verified by each suite's `kill-switch-off` case and `req-id-gate`'s `edit-unreconstructable` case, all passing). |
| REQ-6 | The four plugins must be registered in `.claude-plugin/marketplace.json` alongside the existing `requirements-engineering` entry, mirroring core's multi-plugin marketplace shape. | Given `.claude-plugin/marketplace.json`, when parsed as JSON, then it contains 5 entries in `plugins`: `requirements-engineering`, `req-id-gate`, `traceability-matrix-gate`, `ambiguity-resolution-gate`, `proposal-discipline-gate` (verified: `python3 -c "import json; json.load(open('.claude-plugin/marketplace.json'))"` exits 0, and the five names are present). |
| REQ-7 | This record itself must satisfy all three new phase-2 record gates. | Given this file, when written, then it is not denied by `req-id-gate`, `traceability-matrix-gate`, or `ambiguity-resolution-gate` — self-verified by this record containing REQ-IDs with verification conditions, a complete traceability matrix, and a resolved ambiguity list (this document, all sections below). |

### Non-functional requirements

| ID | Statement | Verification condition |
|---|---|---|
| REQ-8 | No plugin may check more than the one methodology named in the proposal's §0 inventory table. | Given each of the four gate scripts, when read, then each contains exactly one facet's check logic (no combined multi-facet deny message, no shared check function across scripts). |
| REQ-9 | No core canon or sibling-rulebook file may be vendored (copied) into any new plugin. | Given the diff of this delivery, when scanned, then no file under `core/hooks/` is created locally, and no gate script or test file is byte-identical to `pricing/hooks/methodology-gate.sh` or `implementation-rulebook/tests/run-gate-tests.sh` — patterned only (verified: `bash /home/jwjung/tokenmaxxxer/tokenmaxxxer-core/core/hooks/tests/stub-check.sh requirements-engineering/hooks` still reports no vendored copies under the role plugin, unchanged by this delivery). |

## Traceability matrix

| Requirement ID | Requirement Description | Source | Downstream Link |
|---|---|---|---|
| REQ-1 | req-id-gate deny/allow behavior | Proposal §0/§2 (req-id-gate row); adopted norm docs/issue-1/proposals/requirements-engineering.md (b)(1) | `req-id-gate/hooks/req-id-gate.sh`, `req-id-gate/tests/req-id-gate-test.sh` (this delivery) |
| REQ-2 | traceability-matrix-gate deny/allow behavior | Proposal §0/§2 (traceability-matrix-gate row); adopted norm (b)(2) | `traceability-matrix-gate/hooks/traceability-matrix-gate.sh`, `traceability-matrix-gate/tests/traceability-matrix-gate-test.sh` (this delivery) |
| REQ-3 | ambiguity-resolution-gate deny/allow behavior | Proposal §0/§2 (ambiguity-resolution-gate row); adopted norm (b)(3) | `ambiguity-resolution-gate/hooks/ambiguity-resolution-gate.sh`, `ambiguity-resolution-gate/tests/ambiguity-resolution-gate-test.sh` (this delivery) |
| REQ-4 | proposal-discipline-gate deny/allow behavior | Proposal §0/§1; adopted norm (a) | `proposal-discipline-gate/hooks/proposal-discipline-gate.sh`, `proposal-discipline-gate/tests/proposal-discipline-gate-test.sh` (this delivery) |
| REQ-5 | Independent kill switches, fail-closed | Proposal §3 ("Each plugin's kill switch is its own env var") | All four `hooks/*.sh` scripts (this delivery) |
| REQ-6 | Marketplace registration | Proposal §0, Verification plan step 2 | `.claude-plugin/marketplace.json` (this delivery) |
| REQ-7 | This record self-satisfies the new gates | Proposal §2, Verification plan step 6 | This file (current sections) |
| REQ-8 | One methodology per plugin | Proposal §0 ("No plugin checks more than the one methodology") | All four `hooks/*.sh` scripts (this delivery) |
| REQ-9 | No vendoring | Proposal "Canon-reference discipline"; issue-5 precedent | Not yet linked — holds by omission, confirmed by `stub-check.sh` run recorded in "Verification run" below |

## Ambiguity list, resolved

| # | Ambiguous statement | Candidate readings | Resolution | Resolved by |
|---|---|---|---|---|
| AMB-1 | Proposal §0 leaves `req-id-gate`'s "nearby" verification-condition proximity window unspecified in exact line count. | (a) Any verification marker anywhere in the same record; (b) a marker within a small fixed window of lines after the ID. | (b) chosen: an unbounded same-record search would let one verification condition anywhere in the doc silently cover every `REQ-` id, defeating "per-requirement" traceability; a window (implemented as ID line + next ~8 lines) keeps the check attributable to the requirement it names, matching how the proposal ties REQ-1's ordering constraint to `req-id-gate`'s own single-file check. | This role, phase 2, applying proposal §2's `req-id-gate` pseudocode ("REQ-id present without a nearby verification condition") literally, choosing a concrete window since the proposal left it as pseudocode. |
| AMB-2 | Proposal §4 assigns `req-id-gate` the sole agent file (`agents/requirements-scout.md`) but does not specify the agent's exact frontmatter/instruction format. | (a) Match this repo's existing `.claude/agents/` frontmatter shape if one exists; (b) use a minimal `name`/`description` YAML frontmatter plus prose instructions if no local exemplar exists. | (b) chosen: no pre-existing agent file was found under this rulebook's own tree to match against; a minimal frontmatter plus the front-loading instruction from proposal §0 ("name the upstream hypothesis, elicit ambiguities, draft requirement IDs before prose") satisfies the proposal's stated rationale without inventing unrequested structure. | This role, phase 2, per proposal §0's `req-id-gate` agent rationale. |
| AMB-3 | Whether `proposal-discipline-gate`'s section-presence check should require exact heading text or tolerate paraphrase/synonym headings. | (a) Exact heading string match only (e.g. `## Status`); (b) tolerant substring/synonym matching per section. | (b) chosen: the proposal's own pseudocode (§1) checks `section-heading-or-equivalent`, explicitly naming "or equivalent" — an exact-heading-only check would fail proposals using slightly different but equivalent section titles, which the proposal's own wording rules out. | This role, phase 2, per proposal §1's pseudocode wording ("section-heading-or-equivalent"). |

No ambiguity in this delivery was escalated unresolved; all three found
during implementation were resolved as above.

## Open findings

- **No cross-plugin verification of the four gates firing together on one
  write**: each plugin's own test suite exercises it in isolation (per
  the proposal's explicit rejection of shared state/coupling between
  plugins); no test currently drives a single record write through all
  four hooks.json entries simultaneously as Claude Code itself would.
  This is consistent with the proposal's own design (independent plugins,
  independent hooks.json registrations, no shared harness needed per
  proposal §2's "State tracking" subsection) but is noted here as an
  integration gap a future issue could close with an end-to-end
  smoke test if ever wanted.
- Carried forward from `docs/issue-2/reports/requirements-engineering.md`
  (not re-resolved by this delivery): canon's `record-fields-gate.sh`
  remains role-agnostic by design; the four new plugins are this role's
  own compensating enforcement, layered on top, not a canon change.

## Verification run

All commands below were run from the repo root on this branch after the
four plugins were built:

```
$ bash tests/run-gate-tests.sh
== req-id-gate/tests/req-id-gate-test.sh ==
6 passed, 0 failed
== traceability-matrix-gate/tests/traceability-matrix-gate-test.sh ==
6 passed, 0 failed
== ambiguity-resolution-gate/tests/ambiguity-resolution-gate-test.sh ==
6 passed, 0 failed
== proposal-discipline-gate/tests/proposal-discipline-gate-test.sh ==
5 passed, 0 failed
== all plugin gate suites passed ==

$ bash /home/jwjung/tokenmaxxxer/tokenmaxxxer-core/core/hooks/tests/stub-check.sh requirements-engineering/hooks
stub-check: ok — no vendored gate copies under requirements-engineering/hooks
stub-check: ok — requirements-engineering/hooks/directive.sh is a role-directive stub
```

23/23 plugin gate test cases pass; `stub-check.sh` confirms no canon-gate
vendoring was introduced and `directive.sh` remains an unmodified stub,
per Verification plan steps 4 and 5.

loop_state: landed
