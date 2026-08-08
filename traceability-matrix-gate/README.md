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

Beyond the column/row structural checks above, non-empty `Source` and
`Downstream Link` cells are checked for reference shape: a value must be
either the literal `not yet linked` placeholder (case-insensitive), a
repo-relative path (contains a `/` or a `.`, no spaces, not a URL), a
7-40 character hex commit SHA, or a bracketed/linked citation (markdown
`[text](target)` or a bare `[...]`). Free-text prose that matches none of
these shapes is denied, citing the spec's `reference_resolution` rule
(per `docs/issue-19/proposals/spec-alignment.md` item 4). This is a
**shape check, not an existence check** — a syntactically valid path or
SHA that doesn't actually exist in the repo still passes; a live
filesystem/git lookup on every matrix row is out of proportion for this
facet's existing rigor level (D2/D9 above are shape checks too).

The table may also carry an optional fifth **Status** column
(per-requirement status, aliased case-insensitively as `Status`). It is
never required — matrices without it are unaffected. But once a `Status`
header cell is present, every data row must have a non-empty Status
value (any string; the spec marks this field `type: string`, not an
enum) (per `docs/issue-19/proposals/spec-alignment.md` item 5).

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
