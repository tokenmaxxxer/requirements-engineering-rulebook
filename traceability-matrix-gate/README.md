# traceability-matrix-gate

A Claude Code plugin that enforces one methodology facet of the
`requirements-engineering` role: **Facet B — the traceability matrix**.

## What it enforces

Writes to `docs/issue-<n>/reports/requirements-engineering.md` must contain a
"Traceability Matrix" section holding an actual markdown table — a header
row immediately followed by a `| --- | ... |`-style separator row — whose
header cells carry the four columns **ID, Description, Source, Downstream
Link** (structural check, not a substring match against the section's
prose), and that section must contain a row for every `REQ-<id>` token
that appears anywhere in the record. This is checked via a `PreToolUse`
hook on `Write|Edit|MultiEdit` built on core's `gate-lib.sh`/`gate-lib.py`
(core issue #72, referenced from the sibling core install, never vendored)
(see `hooks/traceability-matrix-gate.sh` and `hooks/hooks.json`).

Any write outside that path is ignored (exit 0).

The gate fails closed: any internal error (malformed JSON payload,
unresolvable project root, unparseable resulting content, etc.) denies the
write rather than silently allowing it.

Denials cite `docs/issue-1/proposals/requirements-engineering.md` (b)(2)/(c)
as the source norm.

## Kill switch

Set `TRACEABILITY_MATRIX_GATE_OFF=1` (or `true`/`yes`/`on`,
case-insensitive) to bypass the gate. Any other value — including
empty/unset, a recognized off-spelling (`0`/`false`/`no`/`off`), or an
unrecognized typo — leaves the gate active (`gate_kill_switch_active`,
core issue #72).

## Tests

```
bash tests/traceability-matrix-gate-test.sh
```
