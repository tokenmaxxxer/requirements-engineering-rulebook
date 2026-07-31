# traceability-matrix-gate

A Claude Code plugin that enforces one methodology facet of the
`requirements-engineering` role: **Facet B — the traceability matrix**.

## What it enforces

Writes to `docs/issue-<n>/reports/requirements-engineering.md` must contain a
"Traceability Matrix" section that is a fixed-column table with the four
columns **ID, Description, Source, Downstream Link**, and that section must
contain a row for every `REQ-<id>` token that appears anywhere in the
record. This is checked via a `PreToolUse` hook on `Write|Edit|MultiEdit`
(see `hooks/traceability-matrix-gate.sh` and `hooks/hooks.json`).

Any write outside that path is ignored (exit 0).

The gate fails closed: any internal error (malformed JSON payload,
unresolvable project root, unparseable resulting content, etc.) denies the
write rather than silently allowing it.

Denials cite `docs/issue-1/proposals/requirements-engineering.md` (b)(2)/(c)
as the source norm.

## Kill switch

Set `TRACEABILITY_MATRIX_GATE_OFF=1` (or any value other than
unset/`0`/`false`/`no`/`off`) to bypass the gate entirely.

## Tests

```
bash tests/traceability-matrix-gate-test.sh
```
