# proposal-discipline-gate

A `PreToolUse` gate for the requirements-engineering role. It enforces the
phase-1 (기획서) proposal-structure norm: every phase-1 proposal written to
`docs/issue-<n>/proposals/*requirements-engineering*.md` must contain all 7
required sections — problem/scope, survey-basis, adopted norm, rejected
alternative, plugin-reflection, verification plan, and status. Writes/Edits
that would leave any section out are denied (exit 2) with a message naming
what is missing.

Paths outside this scope are ignored (exit 0).

## Kill switch

Set `PROPOSAL_DISCIPLINE_GATE_OFF=1` (or any value other than
unset/`0`/`false`/`no`/`off`) to bypass the gate entirely.

## Tests

```
bash tests/proposal-discipline-gate-test.sh
```
