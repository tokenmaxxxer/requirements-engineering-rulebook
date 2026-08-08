# req-id-gate

A single-methodology Claude Code plugin for the `requirements-engineering`
role. It owns exactly one methodology:

**Facet A — structured requirements doc.** Every requirement in the
deliverable record (`docs/issue-<n>/reports/requirements-engineering.md`)
must carry a unique `REQ-<id>` and an explicit nearby verification
condition (Given/When/Then, or `verification:` / `verification
condition`), per `docs/issue-1/proposals/requirements-engineering.md`
(b)(1)/(c). Per `docs/issue-19/proposals/spec-alignment.md`, each
`REQ-<id>` must additionally carry an `ears_pattern:` marker and a
`verification_method:` marker (see below) — these are layered on top of
the Given/When/Then check, not a replacement for it.

This plugin does not check anything else (no traceability matrix, no
ambiguity list, no proposal-section discipline) — those live in
sibling plugins per `docs/issue-10/proposals/requirements-engineering-enforcement.md`.

## Components

- `hooks/req-id-gate.sh` — a `PreToolUse` gate on `Write|Edit|MultiEdit`,
  built on core's `gate-lib.sh`/`gate-lib.py` (core issue #72, referenced
  from the sibling core install, never vendored — see the top-level
  README's "Layout" section), that resolves the resulting text of a
  write to the record path and denies (exit 2) if no `REQ-<id>` is
  present, or if any `REQ-<id>` lacks a verification marker — a line
  starting with `Given`/`When`/`Then` or `verification:`/`verification
  condition` — within the contiguous block immediately following the
  `REQ-<id>` line, bounded by the next blank line or the next `REQ-<id>`
  line, capped at 8 lines (structural, not a substring match anywhere in
  an 8-line window). Also denies, within that same window, if the
  `REQ-<id>` lacks a line-anchored `ears_pattern: <value>` marker whose
  value fails the EARS keyword-order grammar check, or lacks a
  line-anchored `verification_method: <value>` marker with a recognized
  value (see "Spec-alignment checks" below). Fails closed on any internal
  error or unreconstructable edit.
- `hooks/hooks.json` — registers the gate.
- `agents/requirements-scout.md` — an agent that front-loads the one
  genuinely front-loadable ordering constraint for this facet:
  hypothesis → ambiguity elicitation → requirement IDs, before prose.

## Spec-alignment checks

Layered on top of the Given/When/Then/`verification:` check above, per
`docs/issue-19/proposals/spec-alignment.md` items 2/3 (both checks must
pass; neither replaces the other):

- **`ears_pattern`.** Every `REQ-<id>` must carry a line-anchored
  `ears_pattern: <value>` marker within the same contiguous block window
  used for the verification condition (next blank line or next
  `REQ-<id>`, capped at 8 lines). `<value>` must be one of the spec's
  six EARS pattern names, and the requirement's statement text (an
  explicit `statement:` line in the block if present, otherwise the
  `REQ-<id>` line itself) must satisfy that pattern's canonical EARS
  keyword-order grammar (case-insensitive):
  - `ubiquitous` — no trigger keyword required; just needs `SHALL`
    somewhere in the statement ("The `<system>` SHALL `<response>`").
  - `event-driven` — `WHEN` before `SHALL` ("WHEN `<trigger>`, the
    `<system>` SHALL `<response>`").
  - `state-driven` — `WHILE` before `SHALL` ("WHILE `<state>`, the
    `<system>` SHALL `<response>`").
  - `optional-feature` — `WHERE` before `SHALL` ("WHERE `<feature>` is
    present, the `<system>` SHALL `<response>`").
  - `unwanted-behaviour` — `IF` before `SHALL` ("IF `<trigger>`, THEN
    the `<system>` SHALL `<response>`"; only the `IF`...`SHALL`
    ordering is enforced).
  - `complex` — at least two of `WHEN`/`WHILE`/`IF`/`WHERE` present
    before `SHALL` (a combination of the above).

  Missing marker, an unrecognized value, or a value whose statement
  text fails the keyword-order check all deny, with a message citing
  the mismatch.

- **`verification_method`.** Every `REQ-<id>` must also carry a
  line-anchored `verification_method: <value>` marker within the same
  window, where `<value>` is a case-sensitive exact match to one of the
  spec's four enum values: `Inspection`, `Analysis`, `Demonstration`,
  `Test`. Missing marker or an unrecognized value denies.

## Kill switch

Set `REQ_ID_GATE_OFF=1` (or `true`/`yes`/`on`, case-insensitive) to
bypass the gate. Any other value — including empty/unset, a recognized
off-spelling (`0`/`false`/`no`/`off`), or an unrecognized typo — leaves
the gate active (`gate_kill_switch_active`, core issue #72: an
unrecognized kill-switch value must never silently disable a gate).

## Tests

```
bash tests/req-id-gate-test.sh
```
