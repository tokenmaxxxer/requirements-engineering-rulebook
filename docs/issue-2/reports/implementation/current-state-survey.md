# Issue-2 current-state survey — canon-reference conversion

Phase 1 (research) deliverable for issue #2 ("core canon 참조 전환: warrant-hunter·게이트
복사본 제거 (core #63/#66 롤아웃)"). This is a survey only — no files in this rulebook
have been changed.

## Issue summary

Core has landed a single canon for machinery every rulebook previously vendored its
own copy of:

- **warrant-hunt** (core issue #63): the rotating-stance background hunt agent now
  lives as core's `warrant/` plugin (size-proportionate budget + miss-streak +
  instrumentation).
- **Three role-agnostic gates** (core issue #66): `trailer-gate.sh`,
  `record-fields-gate.sh`, `handbook-trigger-gate.sh` now live in `core/hooks/`,
  registered once in `core/hooks/hooks.json` for every plugin install, reading role
  identity from `CLAUDE_ROLE` at runtime instead of a role token baked into each
  copy.
- **directive.sh boilerplate**: the shape every rulebook's `SessionStart` directive
  repeated byte-for-byte (trap/kill-switch/guard/opening-closing lines) is now a
  sourceable function, `core_role_directive`, in `core/hooks/lib/role-directive.sh`.

The issue lists five action items (see `## 작업` in the issue body) and one ordering
constraint: this conversion must land before this rulebook's own "rulebook 성숙화"
issue's phase 2.

## What exists in this repo today

```
requirements-engineering/.claude-plugin/plugin.json
requirements-engineering/hooks/hooks.json
requirements-engineering/hooks/directive.sh
requirements-engineering/hooks/trailer-gate.sh
requirements-engineering/hooks/record-fields-gate.sh
requirements-engineering/hooks/handbook-trigger-gate.sh
requirements-engineering/agents/warrant-hunter.md
```

### 1. `agents/warrant-hunter.md` — redundant copy of canon

This file's own header states it is "adapted from implementation-rulebook's
`agents/warrant-hunter.md`" and is explicitly a **skeleton**: "Stances rotate per
invocation (skeleton — enumerate this role's own stance set before shipping...)".
It never got past skeleton stage. Diffing it against core's canon
(`warrant/agents/warrant-hunter.md`, core issue #63) shows the canon file is the
complete, hardened spec (stance rotation, one-file-per-work-unit reporting
convention, the "run it before you read it" method, bounds, output format) that
this rulebook's copy gestures at but does not itself implement. There is no
requirements-engineering-specific *hunting logic* in this file beyond the mandate
line (the role's own `decides` sentence) and the hand-off line — both of which are
role metadata, not hunt-agent behavior.

- Role-specific content worth preserving: the `decides` line ("요구사항이
  검증가능·일관·추적 가능하게 명세되었는가") and the hand-off target
  ("화면/플로우 설계는 → interaction-design").
- Everything else in the file (mandate framing, "Stances rotate...", "Scope" section,
  the entire method/bounds/output apparatus it would need to duplicate to actually
  work) is canon material this rulebook does not need to hold locally at all, since
  core's `warrant/` plugin now supplies the actual hunt-agent runtime.

### 2. Three gate scripts — near-verbatim copies, CLAUDE_ROLE-parameterized in canon

Comparing this repo's three gates against core canon
(`core/hooks/{trailer,record-fields,handbook-trigger}-gate.sh`, core issue #66):

- **`trailer-gate.sh`**: this repo's copy hardcodes `REQUIREMENTS_ENGINEERING_CYCLE_OFF`
  as its kill switch and `"requirements-engineering: refused —"` as its message
  prefix; parses the `-m` argument with a regex instead of `shlex`; has no
  git-root-detection fallback chain. Canon's copy derives both the kill switch
  name (role-blind `TRAILER_GATE_OFF`) and the message prefix from `CLAUDE_ROLE` at
  runtime, tokenizes the commit command properly (rejecting `-F`/`--file`
  file-based messages it cannot verify statically), and resolves the project root
  via `CLAUDE_PROJECT_DIR` with a `git rev-parse --show-toplevel` fallback. This
  repo's copy is the exact "byte-diverged copy whose only real difference was the
  role token" pattern the issue #66 survey describes (38/40 unique hashes across
  the fleet) — role-agnostic logic, no requirements-engineering-specific behavior.
- **`record-fields-gate.sh`**: this repo's copy hardcodes `REQUIRED_FIELDS =
  ["structured-requirements-doc", "traceability-matrix", "ambiguity-list"]` — a
  role-specific *produces* list — where canon's copy checks contract §20's
  role-agnostic minimum field set (what-was-done / why / upstream-basis /
  loop_state / open-findings, with a `TERMINAL` set driven by
  `RECORD_FIELDS_TERMINAL_STATES`) applied to whichever role's own record the
  write targets. This is not pure role-token substitution: canon's version checks
  a materially different (and more complete) set of fields than this repo's copy
  does. The role's actual `produces` value (structured requirements doc /
  traceability matrix / ambiguity list) still needs to be enforced *somewhere*, but
  contract §20's own field set (loop_state, open-findings, etc.) is what canon's
  gate checks — this repo's copy checks neither set correctly relative to canon.
- **`handbook-trigger-gate.sh`**: this repo's copy is a placeholder that always
  `exit 0`s ("placeholder verdict — TODO before this repo is treated as
  load-bearing"). Canon's copy is the complete §21 implementation (operational-
  surface heuristics, handbook-touch check). This repo's copy currently does
  nothing at all — replacing it with the canon reference is a strict improvement,
  not a loss of role-specific behavior (there was none).

None of the three gates in this repo contain requirements-engineering-specific
*mechanism* worth preserving as-is — `record-fields-gate.sh`'s hardcoded
`REQUIRED_FIELDS` list is the one place role identity actually matters, and canon's
generic field check plus a role-configured terminal-states variable
(`RECORD_FIELDS_TERMINAL_STATES`) is the sanctioned way to keep role-specific
behavior explicit per the issue's action item 4.

### 3. `directive.sh` — role-unique content is real and must be preserved

This repo's `directive.sh` already separates role-unique text (`YOU DECIDE`,
`USE_WHEN`, `PRODUCES`, `WRITE_SCOPE`, `HAND-OFF`, `BOUNDARY CASE`) from the
boilerplate (trap, kill-switch case, `CLAUDE_ROLE` guard, heredoc wrapper). The
boilerplate portion is byte-similar to every other rulebook's copy and is exactly
what `core/hooks/lib/role-directive.sh`'s `core_role_directive` function now
supplies. The role-unique values (the five directive lines plus the `BOUNDARY
CASE` paragraph) have no home in canon and must be preserved verbatim when this
file is stubbed.

One structural note: canon's `core_role_directive` takes exactly four positional
values (`you_decide`, `use_when`, `produces`, `hand_off`) and emits a fixed
`RECORD:` trailer itself — it does not have a slot for this rulebook's current
`WRITE_SCOPE` line or its `BOUNDARY CASE` paragraph. Converting to the stub form
means either folding `WRITE_SCOPE`/`BOUNDARY CASE` into one of the four existing
arguments (e.g. appending them to `hand_off`) or accepting that stubbing drops
them from the emitted directive. This is a genuine design question the proposal
must call out rather than silently resolve.

### 4. `hooks.json` — wiring must change with the file deletions

Current `hooks.json` registers `directive.sh` on `SessionStart` and all three
local gates on `PreToolUse`. Once the three gate files are deleted, their
`hooks.json` entries must be removed too (core's own `hooks.json` already fires
them globally per plugin install — this repo does not need to register core's
gates a second time). `directive.sh`'s `SessionStart` entry stays, since every
role still ships its own small stub file.

### 5. `core/hooks/tests/stub-check.sh` — not yet vendored in this repo

This repo has no local copy of `stub-check.sh`. Per the issue's action item 5
("`core/hooks/tests/stub-check.sh` 통과 확인을 record에 기록"), the check is meant to be
run against this rulebook's `hooks/` tree and its pass/fail recorded — the canon
copy (`core/hooks/tests/stub-check.sh`, read from the sibling core checkout
available in this environment) checks for exactly the three gate filenames plus
`parse-check.sh` under a target directory, and separately checks that any
`directive.sh` found is structurally a stub (sources
`role-directive.sh`, calls `core_role_directive`, and has no other
non-comment/non-assignment lines). This repo's own copy of `stub-check.sh` (if
distributed the same way `parse-check.sh` is, per the canon file's own header)
does not yet exist locally; the survey found no `parse-check.sh` in this repo
either. Running `core/hooks/tests/stub-check.sh <path>` against
`requirements-engineering/hooks` today would fail on all three gate names (since
the vendored copies are still present) and would fail the `directive.sh`
structural check too (since the current file has real logic, not the stub form).

### 6. Dependency wiring not yet established

`requirements-engineering/.claude-plugin/plugin.json` and this repo's
`.claude-plugin/marketplace.json` currently have no reference to the `core`
plugin at all — this rulebook does not declare `core` as a dependency, and
nothing in this repo resolves `CLAUDE_PLUGIN_ROOT_CORE`. Canon's own
`role-directive.sh` header documents the sourcing convention as:

```
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/role-directive.sh"
```

i.e. it assumes `core`'s plugin directory is installed as a sibling of this
plugin's own root, or that `CLAUDE_PLUGIN_ROOT_CORE` is set by the harness. This
repo has never installed `core` and there is no local evidence this convention
has been exercised end-to-end by any rulebook yet in this checkout. This is an
open question the proposal flags rather than resolves.

## Mapping to the issue's 5 action items

| # | Action item (issue body) | Current state | Redundant copy? | Role-specific content to preserve |
|---|---|---|---|---|
| 1 | Remove `agents/warrant-hunter.md` and hunt-cadence directives, replace with canon reference | Skeleton copy present, incomplete | Yes — canon (`warrant/agents/warrant-hunter.md`) is the complete spec | `decides` line, hand-off line |
| 2 | Remove `trailer-gate.sh` / `record-fields-gate.sh` / `handbook-trigger-gate.sh` copies and their hook registrations | All three present, one is a no-op placeholder | Yes, all three | `record-fields-gate.sh`'s `REQUIRED_FIELDS` list encodes this role's actual `produces` — needs to survive as role config, not as gate logic |
| 3 | Replace `directive.sh` with stub form (shared function + role-unique part only) | Present, role-unique lines already isolated in the heredoc | Boilerplate portion yes; role-unique lines no | `YOU DECIDE`, `USE_WHEN`, `PRODUCES`, `WRITE_SCOPE`, `HAND-OFF`, `BOUNDARY CASE` |
| 4 | Preserve genuine per-role differences (e.g. terminal loop_state set) via `RECORD_FIELDS_TERMINAL_STATES` | No terminal-state config exists yet; this repo's record-fields-gate checks entirely different (role-specific `produces`) fields, not loop_state at all | N/A — this role has not yet defined its own terminal loop_state set | Needs a decision: what counts as this role's terminal `loop_state` |
| 5 | Confirm `core/hooks/tests/stub-check.sh` passes, record the result | Not yet run in this repo; no local copy of `stub-check.sh` vendored | N/A | N/A — verification step, phase-2 output |

## Non-negotiables carried forward

- `requirements-engineering/.claude-plugin/plugin.json` (role manifest) is
  untouched by this conversion.
- `docs/specs/approvers.md` is untouched by this conversion.
- This role's `decides` / `use_when` / `produces` / `write_scope` / `hand-off`
  values are role identity, not canon material, and must appear unchanged
  somewhere in the post-conversion `directive.sh` (and, per item 4, inform any
  `RECORD_FIELDS_TERMINAL_STATES` configuration this role needs).
