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

- `hooks/req-id-gate.sh` — a `PreToolUse` gate on `Write|Edit|MultiEdit`
  that resolves the resulting text of a write to the record path and
  denies (exit 2) if no `REQ-<id>` is present, or if any `REQ-<id>`
  lacks a verification marker within ~8 lines. Fails closed on any
  internal error or unreconstructable edit.
- `hooks/hooks.json` — registers the gate.
- `agents/requirements-scout.md` — an agent that front-loads the one
  genuinely front-loadable ordering constraint for this facet:
  hypothesis → ambiguity elicitation → requirement IDs, before prose.

## Kill switch

Set `REQ_ID_GATE_OFF=1` (or any value other than unset/`0`/`false`/
`no`/`off`) to bypass the gate entirely.

## Tests

```
bash tests/req-id-gate-test.sh
```
