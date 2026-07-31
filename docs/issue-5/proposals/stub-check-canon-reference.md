# Proposal — retire vendored stub-check.sh, reference core canon (issue #5)

**Phase 1 only.** Nothing described here has been executed. Phase 2 opens
only after an account listed in `docs/specs/approvers.md` approves this PR
(contract v3 s19), matching the issue-2 precedent
(`docs/issue-2/proposals/canon-reference-conversion.md`). See
`docs/issue-5/reports/implementation/survey.md` for the current-state
findings this proposal is based on.

## What to delete

- `requirements-engineering/hooks/tests/stub-check.sh` (89-line vendored
  verbatim copy). This is the only duplicate found; the survey found no
  other vendored copies and no `hooks.json` registration to remove.

## What replaces it

Per core #69's canon ("reference only, no copy" / 참조만, 복사 금지), no
local file replaces the deleted copy. Rulebooks are expected to invoke
`core/hooks/tests/stub-check.sh` from the core install path (sibling core
checkout / core plugin root) rather than a local copy, mirroring the
already-established pattern for `trailer-gate.sh`, `record-fields-gate.sh`,
`handbook-trigger-gate.sh`, and `parse-check.sh` (core #66, issue-2 action
item 2).

Phase 2 must confirm, against the landed core plugin, the exact invocation
form (e.g. `${CORE_PLUGIN_ROOT}/hooks/tests/stub-check.sh <hooks-dir>` or an
equivalent env-var-relative path) before recording a passing run — do not
guess the path here; this proposal only establishes that no local copy is
kept.

## hooks.json changes needed

None. The survey confirmed `requirements-engineering/hooks/hooks.json`
registers only `directive.sh` on `SessionStart` and has no `stub-check`
entry to remove.

## Documentation to update

- `README.md:32-36` — the "Layout" bullet currently says
  `requirements-engineering/hooks/tests/stub-check.sh` is "vendored
  verbatim from core." Phase 2 should replace this bullet with a line
  stating stub-check is referenced from core canon, not vendored (same
  treatment README already gives the four gates one bullet above).
- Historical issue-2 docs (`docs/issue-2/reports/implementation.md`,
  `docs/issue-2/proposals/canon-reference-conversion.md`,
  `docs/issue-2/reports/implementation/current-state-survey.md`) are left
  untouched — they are historical record of a since-superseded convention,
  not live documentation.

## Verification (phase 2)

Phase 2 must run `stub-check.sh` from its core-canon location against
`requirements-engineering/hooks` after the deletion and record the pass/fail
result in `docs/issue-5/reports/implementation.md` (not written yet — that
file is phase-2 output and is explicitly out of scope for this PR).

## Summary table

| Item | Action | Notes |
|---|---|---|
| `requirements-engineering/hooks/tests/stub-check.sh` | Delete | Sole duplicate found |
| `requirements-engineering/hooks/hooks.json` | No change | No stub-check entry present |
| `README.md` Layout bullet | Update | Replace "vendored verbatim" wording with core-reference wording |
| Historical `docs/issue-2/**` | No change | Historical record, predates core #69 |
| `docs/issue-5/reports/implementation.md` | Not created yet | Phase-2 deliverable, written only after approval |

## Status

Proposal only. Awaiting Approve from an approver listed in
`docs/specs/approvers.md` before phase 2 (the actual deletion, README edit,
and verification run) begins.
