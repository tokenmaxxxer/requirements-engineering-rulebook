# Current-state survey — issue-13 (gate A+ remediation)

Scout skip record: skipped, condition "spec leaves no design decision
open" — the issue's precondition mandates reference-adoption of core's
already-landed `core/hooks/lib/gate-lib.sh` +
`docs/handbooks/gate-house-standard.md` (issue-72), with self-reimplementation
explicitly forbidden. The standard fixes the shape of every fix (kill-switch
semantics, JSON-parse deny, path normalize, Write/Edit/MultiEdit
reconstruction, mandatory test groups); the only open work is mapping four
existing gates onto it and deepening two semantic checks the standard does
not itself prescribe wording for (S1/S2 below). Neither is a product-facing
direction choice a market sweep would inform.

## Confirmed defects (read against the four merged plugin hook scripts,
commit 35fbcf3)

### D1 — kill-switch fail-open on unrecognized value (all 4 gates)
Every one of `req-id-gate.sh`, `traceability-matrix-gate.sh`,
`ambiguity-resolution-gate.sh`, `proposal-discipline-gate.sh` uses:
```
case "${X_GATE_OFF:-}" in
  ""|0|false|no|off) ;;
  *) exit 0 ;;
esac
```
Any value that is not a recognized off-spelling — including a typo, `1`,
`true`, `TRUE`, or garbage — falls into `*) exit 0`, which **disables** the
gate. This is exactly bug class 1 that `gate-lib.sh`'s
`gate_kill_switch_active` was written to fix (core issue-72): the intended
inversion is that only a recognized *on*-spelling (`1`/`true`/`yes`/`on`,
case-insensitive) disables; every other value, recognized-off or
unrecognized, stays active. Matches the issue's "킬스위치 비인식 값=활성"
requirement directly.

### D2 — traceability-matrix-gate.sh: substring column-header check (S1)
`traceability-matrix-gate.sh:202`:
```python
has_id = "id" in section_low
```
`section_low` is the lower-cased matrix section text. `"id"` as a bare
substring matches "valid", "identifier", "considering", "guide", etc. — the
gate can be satisfied by prose that never names an ID column. `has_desc`/
`has_source`/`has_downstream` are substring checks of the same kind, just
less collision-prone by luck of English vocabulary. This is the issue's
"컬럼 헤더 검사가 'id' 부분문자열('valid' 매치)로 장식화" finding, confirmed
verbatim.

### D3 — req-id-gate.sh: verification-condition check is keyword-in-window,
not structure (S2)
`req-id-gate.sh:160-190`: for each line carrying a `REQ-<id>` token, the gate
lower-cases an 8-line forward window and checks `any(marker in window for
marker in VERIFY_MARKERS)` where markers are `"given"`, `"when"`, `"then"`,
`"verification:"`, `"verification condition"`. Any of those words appearing
*anywhere* in ordinary prose within 8 lines satisfies the check — e.g. "When
the team decided on this approach, ..." with no Given/When/Then structure
and no adjacency to the REQ line passes. Matches the issue's "검증조건
8줄 창이 'when' 산문으로 만족" finding.

### D4 — no Edit/MultiEdit/adversarial test coverage
`docs/handbooks/gate-tests.md` records 6+6+6+5 = 23 cases across the four
suites. Reading `req-id-gate/tests/req-id-gate-test.sh` (the fullest of the
four): all four "positive-content" cases (`no-req-id`,
`req-id-no-verification`, `req-id-with-verification`, `foreign-path`) drive
the gate exclusively via `tool_name: Write`. The one non-Write case,
`edit-unreconstructable`, checks only that an `Edit` whose `old_string` is
absent from current content is denied — there is no case for a *successful*
Edit or MultiEdit reconstruction (i.e. one that changes gate outcome
correctly), no `replace_all` case, no malformed-JSON case, and no absolute-
path case. The other three suites (traceability-matrix, ambiguity-
resolution, proposal-discipline) were not fully re-read line-by-line here,
but `gate-tests.md`'s case counts (6/6/6/5, none flagged as covering
replace_all or malformed-JSON) and the shared four-gate boilerplate (all
four scripts share the identical `_target`/`_plausible`/`_under`/Write-Edit-
MultiEdit-reconstruct block, byte-for-byte) make it near-certain the same
gap repeats across all four. Matches the issue's "Edit/적대 테스트 0"
finding — 0 cases that actually exercise a *successful* Edit/MultiEdit
outcome, 0 `replace_all`, 0 malformed-JSON, 0 absolute-path.

### D5 — path matching / absolute-path normalization
Each gate's Python payload already does real normalization (`resolve()`
using `os.path.realpath` + `posixpath.normpath`, checked in
`req-id-gate.sh:93-118` etc.) — this part is *not* obviously broken, unlike
D1-D4. The bash-side `_target`/`_plausible`/`_under` block (lines 32-56 of
every script) only informs *root discovery* (deciding whether to trust
`CLAUDE_PROJECT_DIR`), not the final scope match, so an absolute-path
`file_path` should already reach the same `RECORD_RE`/`PROPOSAL_RE` match as
a relative one. The issue nonetheless lists "경로 매칭(절대경로 정규화)" as a
required fix — read as: adopt `gate_normalize_path` so this logic is no
longer 4x hand-rolled and centrally covered by the standard's own test
group 5 (absolute + `./`-prefixed variants), removing the risk of silent
drift rather than a currently-observed break.

### D6 — Write/Edit/MultiEdit reconstruction ignores `replace_all`
All four gates' `Edit`/`MultiEdit` branches call `current.replace(o, n, 1)`
unconditionally — `tool_input.get("replace_all")` is never read. This is
exactly bug class 2 `gate_reconstruct_write` fixes (issue-72 survey section
6, same defect confirmed live in `record-fields-gate.sh` before migration).
Matches the issue's "Edit/MultiEdit/replace_all 완전 재구성" requirement.

### D7 — deny reasons already go to stderr
All four gates' `deny()` writes to `sys.stderr` / `stderr.write`, and the
bash-level `deny()` also writes to `>&2`. This part of the issue's demand
("deny 사유 stderr 전달") is already met — no fix needed, kept as a
compliance-check assertion only (a regression here should be caught by
`compliance-check.sh` and the gates' own tests, not newly built).

### D8 — README ghost files
Not yet checked against the current README; `README.md` in this repo was
touched in the same commit that added the four plugins (67 lines changed).
Full ghost-file audit deferred to phase 2 execution (a mechanical diff of
README claims against `find . -maxdepth 2 -type f`), since it does not
change the gate/plugin architecture the proposal below fixes and re-scouting
it now would not change any design decision in this proposal.

## Core standard referenced (issue-72, landed)

- `core/hooks/lib/gate-lib.sh` — `gate_trap_fail_closed`,
  `gate_kill_switch_active`, `gate_deny`, `gate_allow`,
  `gate_bash_write_targets`.
- `core/hooks/lib/gate-lib.py` — `gate_parse_json_or_deny`,
  `gate_normalize_path`, `gate_reconstruct_write`.
- `docs/handbooks/gate-house-standard.md` — six-case mandatory test group,
  `compliance-check.sh` detector, migration checklist.

Confirmed present in the core repo (not vendored into this rulebook; to be
referenced per `docs/handbooks/canon-scripts.md`'s reference-not-copy rule,
the same posture already used for `stub-check.sh` in this repo per commit
568497d/#7).
