# req-id-gate

A single-methodology Claude Code plugin for the `requirements-engineering`
role. It owns exactly one methodology:

**Facet A — structured requirements doc.** Every requirement in the
deliverable record (`docs/issue-<n>/reports/requirements-engineering.md`)
must carry a unique `REQ-<id>` and an explicit nearby verification
condition (Given/When/Then, or `verification:` / `verification
condition`), per `docs/issue-1/proposals/requirements-engineering.md`
(b)(1)/(c).

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
  an 8-line window). Fails closed on any internal error or
  unreconstructable edit.
- `hooks/hooks.json` — registers the gate.
- `agents/requirements-scout.md` — an agent that front-loads the one
  genuinely front-loadable ordering constraint for this facet:
  hypothesis → ambiguity elicitation → requirement IDs, before prose.

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
