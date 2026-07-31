# Issue-2 phase 2 record — core-canon reference conversion

Phase 2 (execution) deliverable, opened after approvers.md account
`JiwonJung94` posted `APPROVE issue-2/implementation` on the issue
(2026-07-31T08:46:05Z). Executes
`docs/issue-2/proposals/canon-reference-conversion.md`, based on
`docs/issue-2/reports/implementation/current-state-survey.md`'s findings.

Note: the proposal text names the eventual record path as
`docs/issue-2/reports/requirements-engineering.md` (this rulebook's role
name); this session's `CLAUDE_ROLE` is `implementation` (the
role-handoff-contract role actually invoked for this branch), so per
contract v3 s11 (board-gate) this record lands at the path this role
actually writes: `docs/issue-2/reports/implementation.md`.

## Why

Core landed a single canon for machinery every rulebook previously vendored
its own copy of (warrant-hunt: core issue #63; the three role-agnostic
gates and directive boilerplate: core issue #66). Issue #2 asks this
rulebook to convert to referencing that canon instead of carrying
divergent local copies, per the approved proposal.

## Upstream basis

- Issue #2 (this issue), approved via `APPROVE issue-2/implementation` by
  `JiwonJung94` on 2026-07-31T08:46:05Z.
- `docs/issue-2/reports/implementation/current-state-survey.md`.
- `docs/issue-2/proposals/canon-reference-conversion.md` (approved as-is).
- Core issue #63 (`warrant/` plugin canon) and core issue #66 (three
  role-agnostic gates + `role-directive.sh` canon), both merged to core
  main (core PRs #65 and #68).

## What was done

1. Deleted `requirements-engineering/agents/warrant-hunter.md`. Its two
   role-specific lines (`decides` mandate, hand-off target) already live in
   `README.md`'s decides/hand-off block and now also in `directive.sh`'s
   stub call — no new file created. Core's `warrant/` plugin manifest was
   not found to require a per-rulebook agent file for discovery in this
   checkout, and none was added; if that assumption is wrong, re-add on
   demand rather than in this pass.
2. Deleted `requirements-engineering/hooks/trailer-gate.sh`,
   `record-fields-gate.sh`, `handbook-trigger-gate.sh`, and removed their
   `PreToolUse` entries from `hooks.json`. `hooks.json` now registers only
   `directive.sh` on `SessionStart`. Core's `core/hooks/hooks.json` already
   fires all three globally per plugin install.
3. Replaced `directive.sh` with the stub form: sources
   `core/hooks/lib/role-directive.sh`, assigns this role's four values to
   local variables, and calls `core_role_directive` once — no local
   trap/kill-switch/guard boilerplate remains (that logic is now
   `core_role_directive`'s).
   - Resolved the proposal's open design question: `core_role_directive`
     takes exactly four positional values with no slot for `WRITE_SCOPE` or
     `BOUNDARY CASE`. Folded `WRITE_SCOPE` into the `hand_off` argument (both
     are short single-line boundary facts) and relocated the `BOUNDARY
     CASE` paragraph into `README.md`'s decides/use_when/produces block,
     which already carries this role's identity values and is untouched by
     canon. This is a genuine loss of directive-time visibility for
     `BOUNDARY CASE` versus the pre-conversion `directive.sh` (it no longer
     prints at SessionStart) — flagged here per the proposal's instruction,
     not silently accepted.
4. Terminal loop_state set: left canon's default
   (`RECORD_FIELDS_TERMINAL_STATES` unset → `landed`) unexamined-but-
   unchanged. This role's own contract phase-gating (this record only
   exists post-Approve, same as every other role) already targets `landed`
   as its terminal state — no report-only variant (e.g. `scope-proposed`)
   applies here, since this role's output is a full record, not a scope
   proposal. No `RECORD_FIELDS_TERMINAL_STATES` entry was added to
   `hooks.json`.
5. Vendored `core/hooks/tests/stub-check.sh` verbatim to
   `requirements-engineering/hooks/tests/stub-check.sh`, mirroring
   `parse-check.sh`'s distribution convention per the canon file's own
   header (this repo has no `parse-check.sh` of its own to compare against).

## `stub-check.sh` run — result

Command: `bash requirements-engineering/hooks/tests/stub-check.sh requirements-engineering/hooks`

```
stub-check: ok — no vendored 'trailer-gate.sh' under requirements-engineering/hooks
stub-check: ok — no vendored 'record-fields-gate.sh' under requirements-engineering/hooks
stub-check: ok — no vendored 'handbook-trigger-gate.sh' under requirements-engineering/hooks
stub-check: ok — no vendored 'parse-check.sh' under requirements-engineering/hooks
stub-check: ok — requirements-engineering/hooks/directive.sh is a role-directive stub
```

Exit code 0 — all checks pass.

## Open findings

- This role's actual content check — a record really contains a structured
  requirements doc, traceability matrix, and resolved ambiguity list — has
  no home in canon's role-agnostic `record-fields-gate.sh` (which checks
  contract §20's structural fields: what-was-done / why / upstream-basis /
  loop_state / open-findings, not this role's own `produces` list). Not
  re-implemented in this conversion; a follow-up issue should own it.
- No `core` plugin dependency declared in
  `requirements-engineering/.claude-plugin/plugin.json` or a
  `marketplace.json` entry — this checkout has no marketplace wiring for
  `core` yet, and `directive.sh`'s `CLAUDE_PLUGIN_ROOT_CORE` fallback
  (sibling-directory resolution) is unverified end-to-end against an actual
  plugin install. Flagged as a prerequisite for this stub to resolve at
  runtime, not solved by this conversion.

loop_state: landed
