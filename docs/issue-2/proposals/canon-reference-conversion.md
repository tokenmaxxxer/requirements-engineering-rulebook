# Proposal — convert to core-canon references (issue #2)

Phase 1 proposal. Nothing described here has been executed; this is the plan for
phase 2, which opens only after an approvers.md account approves this PR (contract
v3 s19). See `docs/issue-2/reports/implementation/current-state-survey.md` for the
current-state findings this proposal is based on.

One item per issue action item, in the issue's own order.

## Action item 1 — remove `agents/warrant-hunter.md`, reference canon

- **Delete** `requirements-engineering/agents/warrant-hunter.md` in full. It is a
  skeleton copy of core's `warrant/agents/warrant-hunter.md` (core issue #63) with
  no requirements-engineering-specific hunt logic beyond two lines of role
  metadata.
- **Preserve** the two role-specific lines it carried — the `decides` mandate
  ("요구사항이 검증가능·일관·추적 가능하게 명세되었는가") and the hand-off target
  ("화면/플로우 설계는 → interaction-design") — by relocating them into whatever
  role-facing document core's `warrant/` plugin reads role identity from (per core
  issue #63's own convention — this repo does not currently know that convention
  and phase 2 must confirm it against the landed core `warrant/` plugin rather than
  guessing here). If core's `warrant/` plugin reads role mandate from
  `CLAUDE_ROLE` plus this rulebook's `plugin.json` description (which already
  states the `decides` line), no new file may be needed at all — phase 2 should
  check this before adding one.
- **Do not** create a local stub `agents/warrant-hunter.md` unless core's `warrant/`
  plugin actually requires a per-rulebook agent file to exist (e.g. for
  `.claude-plugin` agent discovery). Phase 2 must check core's `warrant/` plugin
  manifest for how it expects to be invoked per-role before deciding whether a
  zero-content stub file is needed here or whether removing the file outright is
  sufficient.
- Remove any hunt-cadence directive text referencing the local warrant-hunter
  (none currently found in `directive.sh` or `hooks.json` in this repo — the
  survey found no cadence wiring beyond the agent file itself).

## Action item 2 — remove the three gate copies and their hook registrations

- **Delete**:
  - `requirements-engineering/hooks/trailer-gate.sh`
  - `requirements-engineering/hooks/record-fields-gate.sh`
  - `requirements-engineering/hooks/handbook-trigger-gate.sh`
- **Edit** `requirements-engineering/hooks/hooks.json`: remove the `PreToolUse`
  entries for all three (the `record-fields-gate.sh` entry under the
  `Write|Edit|MultiEdit` matcher, and the `handbook-trigger-gate.sh` /
  `trailer-gate.sh` entries under the `Bash` matcher). Core's own
  `core/hooks/hooks.json` already fires all three globally (via its `.*` matcher)
  for every plugin install, so this rulebook's `hooks.json` needs no replacement
  entries for them. After the edit, `hooks.json` should register only
  `directive.sh` on `SessionStart` — no `PreToolUse` block should remain unless a
  future, genuinely role-specific gate is added.
- This rulebook's role-specific `produces` values currently hardcoded in
  `record-fields-gate.sh`'s `REQUIRED_FIELDS` (`structured-requirements-doc`,
  `traceability-matrix`, `ambiguity-list`) are not the same field set canon's
  `record-fields-gate.sh` enforces (canon checks contract §20's structural fields:
  what-was-done / why / upstream-basis / loop_state / open-findings). These are
  two different concerns. This rulebook's actual "did the requirements-engineering
  record actually contain a structured requirements doc, traceability matrix, and
  resolved ambiguity list" check has no home in canon and is out of scope for this
  canon-reference conversion — flag it as a follow-up (a role-specific content gate
  is different from the role-agnostic structural gate canon supplies) rather than
  silently dropping the requirement. Phase 2 should not invent a replacement gate
  as part of this conversion; it should record the gap explicitly in this role's
  record.

## Action item 3 — replace `directive.sh` with the stub form

- **Replace** `requirements-engineering/hooks/directive.sh` with a stub of the
  form canon's `stub-check.sh` validates: a source line for
  `core/hooks/lib/role-directive.sh`, then one call to `core_role_directive` with
  this role's four values, and nothing else (no local trap/kill-switch/guard
  boilerplate).
- Concrete proposed content:

  ```bash
  #!/usr/bin/env bash
  . "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/role-directive.sh"
  core_role_directive \
    "YOU DECIDE: 요구사항이 검증가능·일관·추적 가능하게 명세되었는가" \
    "USE_WHEN: product 가설이 확정되어 정식 스펙으로 전환할 때" \
    "PRODUCES (required record fields): structured requirements doc, traceability matrix, ambiguity list resolved" \
    "HAND-OFF: 화면/플로우 설계는 → interaction-design"
  ```

- **Open design question, not resolved here**: canon's `core_role_directive`
  takes exactly four values and has no slot for this role's current `WRITE_SCOPE`
  ("[] (report-only role — no code/doc write outside the record itself)") or its
  `BOUNDARY CASE` paragraph. Proposed resolution for phase 2 to confirm rather than
  silently pick: fold `WRITE_SCOPE` into the `hand_off` argument (since both are
  short, single-line facts about this role's boundary), and treat the longer
  `BOUNDARY CASE` paragraph as content this role must relocate elsewhere (e.g. into
  this repo's own `README.md` "decides/use_when/produces/write_scope/hand-off"
  block, which already exists and is not touched by canon at all) rather than
  trying to fit it through `core_role_directive`'s fixed four-argument shape. This
  is a genuine loss of directive-time visibility for `BOUNDARY CASE` compared to
  today's `directive.sh`, and should be called out to the approver explicitly
  rather than assumed acceptable.

## Action item 4 — preserve genuine per-role differences via `RECORD_FIELDS_TERMINAL_STATES`

- This role's `directive.sh` does not currently define what `loop_state` value(s)
  count as terminal for requirements-engineering. Canon's default
  (`RECORD_FIELDS_TERMINAL_STATES` unset) is `landed`. Before phase 2 lands the
  stub conversion, confirm with the approver whether `landed` is this role's
  actual terminal state, or whether — being a report-only role with `write_scope:
  []` — it needs an additional or different terminal state (e.g. a
  proposal-only role might terminate at `scope-proposed`, per canon's own
  record-fields-gate.sh header example). If this role's terminal set differs
  from canon's default, add `RECORD_FIELDS_TERMINAL_STATES` to
  `requirements-engineering/hooks/hooks.json`'s environment for the relevant
  hook entry (or to a repo-level env convention if one exists — phase 2 must
  check how other converted rulebooks set this, once any exist, per the
  "siblings" principle) rather than leaving canon's default unexamined.

## Action item 5 — confirm `core/hooks/tests/stub-check.sh` passes, record it

- **Vendor** `core/hooks/tests/stub-check.sh` into this repo the same way
  `parse-check.sh` is distributed (per the canon file's own header: "dropped
  alongside it and run from the same harness... every rulebook copies this file
  verbatim"). Proposed location: `requirements-engineering/hooks/tests/stub-check.sh`
  (mirroring where `parse-check.sh` lives per canon's comment, though this repo
  currently has no `hooks/tests/` directory and no `parse-check.sh` either —
  phase 2 should confirm the intended location against another already-converted
  rulebook if one exists by then).
- **Run** `stub-check.sh requirements-engineering/hooks` after the deletions and
  stub replacement above, and confirm it reports `ok` for all three gate names
  plus the `directive.sh` structural check.
- **Record** the pass/fail output of that run in
  `docs/issue-2/reports/requirements-engineering.md` (phase-2 output, per contract
  v3 s19 — not written in phase 1).

## Files affected (summary)

| File | Action |
|---|---|
| `requirements-engineering/agents/warrant-hunter.md` | delete |
| `requirements-engineering/hooks/trailer-gate.sh` | delete |
| `requirements-engineering/hooks/record-fields-gate.sh` | delete |
| `requirements-engineering/hooks/handbook-trigger-gate.sh` | delete |
| `requirements-engineering/hooks/directive.sh` | replace with stub calling `core_role_directive` |
| `requirements-engineering/hooks/hooks.json` | remove the three gates' `PreToolUse` entries; keep `directive.sh` on `SessionStart` |
| `requirements-engineering/hooks/tests/stub-check.sh` (new) | vendor canon copy verbatim |
| `requirements-engineering/.claude-plugin/plugin.json` | unchanged |
| `docs/specs/approvers.md` | unchanged |
| `README.md` | update Layout section to match the new, smaller file set; carry `BOUNDARY CASE` text here if action item 3's open question resolves that way |

## Not proposed here

- Declaring `core` as a formal plugin dependency in
  `.claude-plugin/marketplace.json` or `requirements-engineering/.claude-plugin/plugin.json`
  — the survey found no such wiring exists anywhere in this checkout yet, and this
  conversion's file-level scope (delete/stub specific files) does not itself
  require resolving how `core`'s plugin gets installed alongside this one. Flagging
  this as a prerequisite the approver should confirm is handled at the
  installation/marketplace level before phase 2's `directive.sh` stub can actually
  resolve `core/hooks/lib/role-directive.sh` at runtime.
- Any change to this role's actual content-level requirements gate (checking that
  a record really contains a structured requirements doc / traceability matrix /
  ambiguity list) — per action item 2's discussion, that is a different, still-
  unowned concern this conversion surfaces but does not solve.

## Order constraint (from the issue)

Per the issue body, this conversion must complete before this rulebook's own
"rulebook 성숙화" (rulebook maturation) issue's phase 2. This proposal does not
depend on that issue and can land independently; phase 2 of that issue should not
begin until this issue's phase 2 (the actual conversion) is merged.
