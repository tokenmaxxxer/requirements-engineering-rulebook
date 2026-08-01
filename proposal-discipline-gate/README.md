# proposal-discipline-gate

A `PreToolUse` gate for the requirements-engineering role. It enforces the
phase-1 (기획서) proposal-structure norm: every phase-1 proposal written to
`docs/issue-<n>/proposals/*requirements-engineering*.md` must contain all 7
required sections — problem/scope, survey-basis, adopted norm, rejected
alternative, plugin-reflection, verification plan, and status. Writes/Edits
that would leave any section out are denied (exit 2) with a message naming
what is missing.

Paths outside this scope are ignored (exit 0). Built on core's
`gate-lib.sh`/`gate-lib.py` (core issue #72, referenced from the sibling
core install, never vendored) for the kill-switch, path-normalization,
and Write/Edit/MultiEdit reconstruction machinery.

## Kill switch

Set `PROPOSAL_DISCIPLINE_GATE_OFF=1` (or `true`/`yes`/`on`,
case-insensitive) to bypass the gate. Any other value — including
empty/unset, a recognized off-spelling (`0`/`false`/`no`/`off`), or an
unrecognized typo — leaves the gate active (`gate_kill_switch_active`,
core issue #72).

## Tests

```
bash tests/proposal-discipline-gate-test.sh
```
