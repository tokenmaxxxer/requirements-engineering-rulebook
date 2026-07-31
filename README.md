# requirements-engineering-rulebook

Rulebook for the `requirements-engineering` role (contract v3 role-handoff protocol), split off
per `docs/issue-160/proposals/role-taxonomy.md`'s round-4 promotion and
generated as skeleton scaffolding by issue-167.

- **decides**: 요구사항이 검증가능·일관·추적 가능하게 명세되었는가
- **use_when**: product 가설이 확정되어 정식 스펙으로 전환할 때
- **produces**: structured requirements doc, traceability matrix, ambiguity list resolved
- **write_scope**: []
- **hand-off**: 화면/플로우 설계는 → interaction-design

**BOUNDARY CASE**: if the work in front of you drifts outside `decides`
above, stop and hand off per the arrow — do not silently absorb another
role's scope. Record the hand-off point in this role's record before
opening the next role's session.

## Install

```
claude plugin marketplace add tokenmaxxxer/requirements-engineering-rulebook
claude plugin install requirements-engineering
```

## Layout

- `requirements-engineering/.claude-plugin/plugin.json` — plugin manifest
- `requirements-engineering/hooks/hooks.json` — SessionStart wiring only; the
  trailer/record-fields/handbook-trigger gates and the warrant-hunter agent
  are core canon now (core issue #63/#66) and fire globally per plugin
  install — this rulebook carries no local copies
- `requirements-engineering/hooks/directive.sh` — stub SessionStart role
  directive: sources `core/hooks/lib/role-directive.sh` and calls
  `core_role_directive` with this role's four values
- `requirements-engineering/hooks/tests/stub-check.sh` — vendored verbatim
  from core; drift detector confirming no gate copy has regrown locally and
  that `directive.sh` stays in stub form
- `docs/specs/approvers.md` — Approve-authority allowlist (see below)

This role's `record-fields-gate.sh`-era `produces` check (structured
requirements doc / traceability matrix / ambiguity list, as distinct from
contract §20's role-agnostic structural fields that canon's gate now
checks) has no home in canon and is not re-implemented here — see
`docs/issue-2/reports/requirements-engineering.md` for the open follow-up.

This is scaffolding, not a finished rulebook: fill in doctrine detail,
handoff enforcement, and any role-specific progress gate before treating
it as load-bearing.
