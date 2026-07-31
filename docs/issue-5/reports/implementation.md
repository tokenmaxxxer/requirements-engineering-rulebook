# Issue-5 phase 2 record — stub-check.sh canon reference

Phase 2 (execution) deliverable, opened after approvers.md account
`JiwonJung94` posted `APPROVE issue-5/implementation` on the issue.
Executes `docs/issue-5/proposals/stub-check-canon-reference.md`, based on
`docs/issue-5/reports/implementation/survey.md`'s findings.

## Why

Core #69 extends the core #66/#68 "reference, don't vendor" canon to
`stub-check.sh` itself: rulebooks are expected to invoke
`core/hooks/tests/stub-check.sh` from the core install rather than keep a
local verbatim copy. Issue #5 asks this rulebook to drop its vendored copy
(introduced by the issue-2 conversion) and confirm the core-reference
invocation still passes.

## Upstream basis

- Issue #5 (this issue), approved via `APPROVE issue-5/implementation` by
  `JiwonJung94`, listed in `docs/specs/approvers.md`.
- `docs/issue-5/reports/implementation/survey.md`.
- `docs/issue-5/proposals/stub-check-canon-reference.md` (approved as-is).
- Core issue #69 (stub-check.sh de-vendoring canon).

## What was done

1. Deleted `requirements-engineering/hooks/tests/stub-check.sh` (89-line
   vendored verbatim copy) — the sole duplicate the survey found.
2. `requirements-engineering/hooks/hooks.json` — no change. Confirmed (per
   survey) it registers only `directive.sh` on `SessionStart` and has no
   `stub-check` entry to remove.
3. Updated `README.md`'s Layout bullet: replaced the "vendored verbatim"
   wording with a line stating stub-check is referenced from core canon by
   path, not vendored.

## Verification

Located the core canon copy at this environment's core install path
(`core/hooks/tests/stub-check.sh`) and ran it by reference against this
rulebook's hooks tree, both before and after the deletion:

Command: `bash <core-install>/hooks/tests/stub-check.sh requirements-engineering/hooks`

```
stub-check: ok — no vendored 'trailer-gate.sh' under requirements-engineering/hooks
stub-check: ok — no vendored 'record-fields-gate.sh' under requirements-engineering/hooks
stub-check: ok — no vendored 'handbook-trigger-gate.sh' under requirements-engineering/hooks
stub-check: ok — no vendored 'parse-check.sh' under requirements-engineering/hooks
stub-check: ok — requirements-engineering/hooks/directive.sh is a role-directive stub
```

Exit code 0 in both runs. stub-check's own checks are absence-based for
the four core-canon gates and structural for `directive.sh`; it does not
gate on whether its own script is vendored, so the pass result is
unchanged across the deletion. This confirms the canon-reference
invocation form (`<core-root>/hooks/tests/stub-check.sh <hooks-dir>`)
works against this rulebook and that no drift exists.

## Open findings

- Historical `docs/issue-2/**` records of the superseded vendoring
  convention are left untouched, per the proposal — they document a
  since-superseded decision, not live guidance, and were out of scope for
  this issue.
- The exact core install path used for verification here
  (`core/hooks/tests/stub-check.sh`) is an artifact of this session's
  environment (no sibling `core/` checkout lives in this repo's working
  tree, per the phase-1 survey); a real end-user install still needs
  `directive.sh`'s existing `CLAUDE_PLUGIN_ROOT_CORE`-style resolution to
  find it at runtime — unchanged from, and not solved by, this issue.

loop_state: landed
