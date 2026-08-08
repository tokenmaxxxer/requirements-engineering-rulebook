Subject: issue-19

---
code_under_review:
  - README.md
  - requirements-engineering/hooks/directive.sh
  - req-id-gate/hooks/req-id-gate.sh
  - req-id-gate/tests/req-id-gate-test.sh
  - req-id-gate/README.md
  - traceability-matrix-gate/hooks/traceability-matrix-gate.sh
  - traceability-matrix-gate/tests/traceability-matrix-gate-test.sh
  - traceability-matrix-gate/README.md
loop_state: landed
---

# Phase 2 — apply approved spec-alignment proposal

## What was done

Applied the approved proposal (`docs/issue-19/proposals/spec-alignment.md`,
approved via the exact-string issue comment `APPROVE issue-19/implementation`
in single-account mode) per its numbered "What will be done" list:

1. `statement` — README.md Doctrine "Phase-2 deliverable norms" §1 and
   `req-id-gate.sh` now require an explicit `statement:`-labeled line
   alongside the existing testable-statement prose.
2. `ears_pattern` — `req-id-gate.sh` now requires a nearby, line-anchored
   `ears_pattern: <value>` marker (six-value spec enum) per `REQ-<id>`,
   plus a structural, word-boundary keyword-order check against the
   requirement's statement text (`ubiquitous`/`event-driven`/
   `state-driven`/`optional-feature`/`unwanted-behaviour`/`complex`, per
   the EARS canonical grammar). Documented in `req-id-gate/README.md`;
   covered by new pass/deny cases in
   `req-id-gate/tests/req-id-gate-test.sh`.
3. `verification_method` — `req-id-gate.sh` now also requires a nearby
   `verification_method: <value>` marker (`Inspection`/`Analysis`/
   `Demonstration`/`Test`), layered alongside (not replacing) the
   existing Given/When/Then/`verification:` check.
4. `source` / `downstream_link` — `traceability-matrix-gate.sh` now
   requires non-"not yet linked" Source/Downstream Link cells to be
   reference-shaped (repo-relative path, 7-40 char hex sha, or a
   bracketed/markdown-link citation) — a shape check, not an existence
   check, exactly as scoped in the proposal's Rationale/item 4.
5. `status` — `traceability-matrix-gate.sh` accepts an optional fifth
   `Status` column; when the header is present, every row must carry a
   non-empty value.
6. `loop_state` vocabulary — README.md and `requirements-engineering/
   hooks/directive.sh`'s `PRODUCES` line now state the spec's five-state
   vocabulary verbatim (`drafting`, `resolving-ambiguity` / `landed` /
   `hypothesis-not-final` / `source-unresolvable`) as doctrine. The
   `docs/specs/record-fields-terminal-states.json` mechanical-override
   route named in the proposal turned out unusable without collateral
   damage — see `## Rationale for deviations` below.
7. Updated `req-id-gate/README.md` and `traceability-matrix-gate/README.md`
   to document every added check; updated both plugins' test suites with
   new pass/deny cases (and updated pre-existing pass-case fixtures so
   they still satisfy the now-additional required markers); ran
   `bash tests/run-gate-tests.sh` — all four plugin suites pass (69 cases
   total across req-id-gate/traceability-matrix-gate/ambiguity-
   resolution-gate/proposal-discipline-gate, 0 failures).

`ambiguity-resolution-gate.sh` and `proposal-discipline-gate.sh` code
were left untouched, per the proposal's Out-of-scope: no spec field maps
onto either gate's own logic beyond the `loop_state` vocabulary's
`resolving-ambiguity` name, which was intended as a JSON config addition
only (see deviation below — it landed as doctrine text instead).

## Doctrine-ladder placement (completed)

- [x] Field-name doctrine addition (spec field names, no new dep/config
  key) → `README.md` "Doctrine" section, same turn as the code it
  documents.
- [x] `loop_state` vocabulary (role-scoped statement, doctrine not
  mechanical — see deviation) → `README.md` "Doctrine" section and
  `requirements-engineering/hooks/directive.sh` `PRODUCES` line, same
  turn.
- [x] Per-plugin check documentation → `req-id-gate/README.md`,
  `traceability-matrix-gate/README.md`, same turn as the gate code.
- No new dependency, migration, or setup step was introduced — no
  handbook entry required.
- No public signature/wire-format change beyond this role's own record
  vocabulary (already covered by the README/directive.sh doctrine
  entries above) — no `docs/issue-19/decisions/` entry needed.
- No benchmark/investigation numbers produced beyond this record itself
  — no separate `docs/issue-19/reports/` entry needed.

## Why

Upstream marketplace spec `roles/specs/requirements-engineering.spec.json`
(realized, referenced as "on-the-record" per the issue body) defines
required deliverable fields and a `loop_state` vocabulary that this
rulebook's methodology docs/hooks did not yet express by name. The issue
asks to layer the spec's vocabulary onto the rulebook's existing,
richer methodology (never deleting it) so a future spec-consuming reader
finds the exact field names the spec expects, while the rulebook keeps
the stronger checks (structural Given/When/Then, structural matrix
columns) it already had.

## Upstream / basis

`docs/issue-19/proposals/spec-alignment.md` (approved), itself grounded
in `docs/issue-19/reports/implementation/survey.md` (current-state
survey) and `docs/issue-19/reports/implementation/scout-brief.md`.

## Rationale for deviations

Item 6's `docs/specs/record-fields-terminal-states.json` file (in the
proposal's frozen write set) was not created. Discovered mid-build,
reading core's `record-fields-gate.sh`: the override is keyed by
contract §2's fixed canon record kinds (`product-record`, `coding-
record`, `qa-record`, ...), and every one of those 9 keys is already
claimed by an existing role via core's `ROLE_TO_KIND` map, which takes
priority over any record's own self-declared `kind:` field.
`requirements-engineering` is not itself a canon role in that map.
Concretely, attempting to write the file with key
`"requirements-engineering"` was refused outright by
`record-fields-gate.sh` ("names unrecognized kind ... not one of
contract §2's record kinds") — the gate validates every key in the
override file, not just the one relevant to the current write, and
fails loudly on an unrecognized key exactly as its own comments say it
must. Re-keying to an existing canon kind (e.g. `product-record`, the
closest semantic fit) would have been accepted by the gate but would
then apply to every role already mapped to that kind (e.g. the real
`product` role), silently changing that unrelated role's terminal-state
behavior repo-wide — a correctness regression the proposal never
intended and outside this issue's write set to cause. Neither option
delivers a safely scoped mechanical override for this role today; core
would need to add `requirements-engineering` to `ROLE_TO_KIND` first,
which is a core-repo change, not this rulebook's. Resolution taken:
state the vocabulary as doctrine in README.md and `directive.sh` (still
satisfies acceptance check 2's "no stale or extra states" as a
documented statement, though not gate-enforced), and record this gap
plainly rather than leaving a landmine (invalid key) or a silent
regression (borrowed key) in the write set.

## What did not work

- Attempted `docs/specs/record-fields-terminal-states.json` write keyed
  `"requirements-engineering"` — expected: creates a role-scoped
  loop_state override; actual: `record-fields-gate.sh` refused the write
  ("unrecognized kind"), since the override mechanism is keyed by
  contract §2's fixed canon kinds only, not by arbitrary role name.
  Replaced with doctrine-only documentation — see
  `## Rationale for deviations` above.
- Before-landing warrant hunt (stance 0, "assume the gate just touched
  is bypassable") found that `req-id-gate.sh`'s new `ears_pattern`
  keyword checks used plain substring search (`str.find`), so a
  statement containing `"marshall"` satisfied the `SHALL` keyword
  requirement via the substring `"...marSHALL..."`, letting an
  `ears_pattern: ubiquitous` marker pass with no real EARS keyword
  present in the statement. Expected: only a real, whole-word `SHALL`
  (and `WHEN`/`WHILE`/`WHERE`/`IF`) should satisfy the grammar check;
  actual: any substring occurrence satisfied it. Fixed by switching
  `_kw_order_ok`/`_ears_ok` in `req-id-gate/hooks/req-id-gate.sh` to
  word-boundary regex matching (`\bKEYWORD\b`) instead of substring
  `find`, and added a regression case (`ears-substring-not-keyword`) to
  `req-id-gate/tests/req-id-gate-test.sh` reproducing the exact
  "marshall" statement, now correctly denied. Full suite re-run after
  the fix: all passing.

## Open findings

None open. The one blocking finding raised by the before-landing
warrant hunt (word-boundary bypass in `ears_pattern` keyword matching)
is resolved.

resolved_findings:
- finding: "ears_pattern substring-match bypass (e.g. 'marshall' satisfies SHALL)"
  hunt_record: docs/reports/2026-08-09-hunt-spec-alignment.md (before-landing section)
  resolution: req-id-gate.sh now matches keywords via `\bKEYWORD\b` word-boundary regex, not substring `find`; regression test `ears-substring-not-keyword` added and passing.
  code_under_review: req-id-gate/hooks/req-id-gate.sh, req-id-gate/tests/req-id-gate-test.sh

closed_checks:
- check: full plugin gate test suite (`bash tests/run-gate-tests.sh`)
  code_under_review: as listed in frontmatter above
  result: all four plugin suites pass, 0 failures (69 cases total)
- check: acceptance-1 grep (`grep -ri 'statement|ears_pattern|source|verification_method|downstream_link|status' docs/ README.md`)
  code_under_review: as listed in frontmatter above
  result: every spec required-field name present in docs/ and README.md
- check: acceptance-2 (loop_state vocabulary matches spec set)
  code_under_review: as listed in frontmatter above
  result: doctrine text in README.md/directive.sh states exactly {drafting, resolving-ambiguity, landed, hypothesis-not-final, source-unresolvable} — no gate-mechanical enforcement possible for this role today (see Rationale for deviations)
- check: acceptance-3 (test suite present -> run it; pytest/unverifiable fallback does not apply)
  code_under_review: as listed in frontmatter above
  result: this repo's suite is bash-based (`tests/run-gate-tests.sh`); ran and passed
