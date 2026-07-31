# Current-state survey — stub-check.sh copies (issue #5)

Phase 1 survey. No changes executed. Basis for
`docs/issue-5/proposals/stub-check-canon-reference.md`.

## 1. Canonical source

Per issue #5 and core #69: `core/hooks/tests/stub-check.sh` is the sole canon
copy. Rulebooks reference it and run it; they do not vendor it. This is a
tightening of the earlier core #66-era convention (see issue-2 precedent
below), which had rulebooks vendor `stub-check.sh` verbatim while treating
`trailer-gate.sh` / `record-fields-gate.sh` / `handbook-trigger-gate.sh` /
`parse-check.sh` as no-longer-vendored core hooks. Core #69 extends the same
"no local copy" rule to `stub-check.sh` itself.

`core/hooks/tests/stub-check.sh` was not found in this repo's working tree
(no sibling `core/` checkout present here) — its content is known only via
the vendored copy below, whose header states it is "distributed to every
rulebook … dropped alongside it" and "every rulebook copies this file
verbatim."

## 2. Duplicate copies found in this repo

`grep -rn "stub-check" .` (excluding `.git`) turns up exactly one vendored
script and several references to it:

| Path | Nature |
|---|---|
| `requirements-engineering/hooks/tests/stub-check.sh` | **The copy to remove** — 89-line vendored verbatim copy of core canon, per issue-2's action item 5. This is the file issue #5 targets. |
| `README.md:35` | Documents the vendored copy under "Layout" ("vendored verbatim from core; drift detector…") — needs updating once the file is removed. |
| `docs/issue-2/reports/implementation.md:71-85` | Historical record of the issue-2 vendoring action and its `stub-check.sh` pass output. Left as-is (historical record, not touched). |
| `docs/issue-2/proposals/canon-reference-conversion.md:68-141` | Historical proposal that specified vendoring `stub-check.sh` (issue-2 action item 5). Left as-is. |
| `docs/issue-2/reports/implementation/current-state-survey.md:133-177` | Historical issue-2 survey noting stub-check.sh was "not yet vendored" at that time. Left as-is. |

Only **one** live duplicate exists: `requirements-engineering/hooks/tests/stub-check.sh`.
No `docs/handbooks/canon-scripts.md` file exists in this repo (issue text
references it as living in the core/canon-scripts handbook, not locally).

## 3. hooks.json registration status

`find . -name hooks.json -not -path "*/.git/*"` finds exactly one file:
`requirements-engineering/hooks/hooks.json`. Its content:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          { "type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/hooks/directive.sh" }
        ]
      }
    ]
  }
}
```

`grep` for "stub-check" inside it: **no match**. `stub-check.sh` is a test
script invoked ad hoc / by CI or a run-tests convention, not wired through
`hooks.json` as a Claude Code hook. There is therefore **nothing to remove
from hooks.json** for this issue — only the vendored file and its README
mention need updating.

## 4. Git history

`git log --oneline -- '*stub-check*'` returns one commit:
`c1a1a8b deliver(implementation): convert to core-canon references (issue-2) (#4)`
— the commit that introduced the vendored copy per issue-2 action item 5.

## 5. issue-2 precedent pattern (for reuse)

`docs/issue-2/proposals/canon-reference-conversion.md` established this
repo's phase-1/phase-2 contract:

- Phase 1 = survey + proposal PR, no execution, gated on an
  `docs/specs/approvers.md`-listed approver's Approve (contract v3 s19).
- Phase 2 = execute the proposal (delete files, edit hooks.json, run
  verification, write `docs/issue-N/reports/implementation.md`) only after
  approval.
- Each action item in the proposal names: what to delete, what (if
  anything) replaces it, what hooks.json edit is needed, and what
  verification command confirms the result.
- `docs/specs/approvers.md` exists at that path and lists the Approve-authority
  allowlist (contents not otherwise needed for this survey).

Issue #5 is the direct sequel: core #66 already demoted the four
role-agnostic gates + parse-check.sh to core-fired hooks (handled in
issue-2); core #69 now demotes `stub-check.sh` itself the same way, closing
the loop the issue-2-era `stub-check.sh` header (see section 2) already
anticipated ("core is canon by definition").
