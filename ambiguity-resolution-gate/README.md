# ambiguity-resolution-gate

A Claude Code plugin enforcing one requirements-engineering methodology facet:
**Facet C — ambiguity list, resolved.**

## What it enforces

Per `docs/issue-1/proposals/requirements-engineering.md` (b)(3)/(c), the
requirements-engineering deliverable record
(`docs/issue-<n>/reports/requirements-engineering.md`) must carry a section
headed "ambiguity", and that section must either:

- explicitly state that no ambiguities were found, or
- show every listed ambiguity resolved (`resolution:`) or explicitly
  escalated (`escalated`).

The gate is a `PreToolUse` hook (`hooks/ambiguity-resolution-gate.sh`)
matching `Write|Edit|MultiEdit`. It reads the resulting content of the write
(reconstructing Edit/MultiEdit against the file's current content), and
denies the tool call (exit 2) when the ambiguity facet is missing. It is
scoped only to `docs/issue-<n>/reports/requirements-engineering.md`; writes
to any other path are allowed silently. It fails closed on any internal
error (malformed payload, unreadable file, unparseable JSON, etc.).

## Kill switch

Set `AMBIGUITY_RESOLUTION_GATE_OFF=1` (or any value other than
unset/`0`/`false`/`no`/`off`) to bypass the gate entirely.

## Tests

```
bash tests/ambiguity-resolution-gate-test.sh
```
