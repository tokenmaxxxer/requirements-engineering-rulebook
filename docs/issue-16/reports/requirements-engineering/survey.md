# Current-state survey — issue #16 (2026-08-01 재감사 잔여 결함)

## Scope

Confirms, against the merged code (commit 4ddc4f6, issue #13 delivery) and
the landed preconditions (core issue #75, on-the-record #182), each item
the issue #16 body lists. Read in full: all four gate scripts
(`req-id-gate/hooks/req-id-gate.sh`, `traceability-matrix-gate/hooks/
traceability-matrix-gate.sh`, `ambiguity-resolution-gate/hooks/
ambiguity-resolution-gate.sh`, `proposal-discipline-gate/hooks/
proposal-discipline-gate.sh`), all four `hooks.json`, all four test
suites, all five READMEs, all five `plugin.json` manifests,
`tests/run-gate-tests.sh`, `docs/handbooks/gate-tests.md`, core's
`core/hooks/lib/gate-lib.sh`/`gate-lib.py` and
`core/hooks/tests/run-gate-lib-tests.sh` (issue-75 delivery, confirms the
missing-core test shape core itself now enforces on its own gates).

## D9 — column-cell substring bug survives the D2 "fix" ("Resource가 Source 만족")

`traceability-matrix-gate.sh`'s `col_present()` (around line 197) does:

```python
def col_present(needles):
    return any(any(n in cell for n in needles) for cell in header_cells)
```

with `REQUIRED_COLS` needles `("id",)`, `("description","desc")`,
`("source",)`, `("downstream",)`. This is substring-**within-cell**, not
whole-cell match. Issue #13's D2 fix closed the *section-text* substring
hole (`'id' in 'valid'` matched anywhere in prose) but left this
*cell-text* substring hole open: a header cell literally reading
`Resource` contains `"source"` as a substring and satisfies the Source
column requirement; a cell reading `Valid` contains `"id"` and would
satisfy ID the same way. Confirmed by direct string test: `"source" in
"resource".lower()` → `True`. This is exactly the residual defect the
issue names ("컬럼 셀 substring — Resource가 Source 만족").

## D10 — proposal-discipline-gate suite: no plain-`Edit`-allow case

`proposal-discipline-gate/tests/proposal-discipline-gate-test.sh` (13
cases, matches `docs/handbooks/gate-tests.md`'s count) has:
- `run_edit_replace_all` (line 105) — single `Edit`, asserts **deny**
  (content stays non-compliant after the edit).
- `run_multiedit_mixed` (line 115) — `MultiEdit`, asserts **allow**
  (content becomes ALL_SEVEN).

No case exercises a single `Edit` whose reconstructed result is the
compliant seven-section document and asserts **allow**. Every allow-path
case for this gate is either `Write`-based (line 86 `run allow
all-seven-sections`) or `MultiEdit`-based (line 115). This is the gap
issue #16 names as "phase1-proposal 스위트 Edit 케이스 부재" — the
suite gating the phase-1 proposal record has an Edit-deny case and an
Edit-adjacent (MultiEdit)-allow case, but no Edit-allow case, so a
regression that broke `gate_reconstruct_write` specifically for the
single-`Edit`-allow path would pass this suite undetected.

## D11 — missing-core case absent from all four suites (blocks issue #16 req. 3)

Core issue #75 (landed, `core/hooks/tests/run-gate-lib-tests.sh` group 7,
line 230) added a mandatory "missing-core" case to core's own gate test
harness: point `CLAUDE_PLUGIN_ROOT_CORE` at a nonexistent directory and
assert the gate **denies** (fails closed) rather than crashing with an
unrelated exit code or silently allowing. `grep -rln "missing.core"
--include=*.sh .` across this repo returns nothing — none of the four
gates' own suites have this case, even though all four source
`gate-lib.sh` via the identical `${CLAUDE_PLUGIN_ROOT_CORE:-...}` pattern
core's own gates use and core issue-75 was filed specifically to fix this
failure mode. Issue #16 requirement 3 ("missing-core 케이스 포함 전
스위트 배송 상태 green") names this directly as a required addition.

Checked whether the preamble already fails closed without a dedicated
test: all four gates' first three lines are

```bash
#!/usr/bin/env bash
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/gate-lib.sh"
gate_trap_fail_closed
```

`set -uo pipefail` is not in effect yet at the `.` (source) line — it
appears later, after the file's doc-comment block. If `CLAUDE_PLUGIN_ROOT_CORE`
points nowhere, the `.` command fails, but without `set -e` the script
does not stop: it falls through to `gate_trap_fail_closed`, an undefined
function, which does halt the script (bash exits nonzero on a bare
command-not-found in a non-interactive script under most invocations) —
but at whatever bash's command-not-found exit code is (127), not the
gate's own deny code (2). A caller (or a test) that only checks "did the
tool call get blocked" via a nonzero exit still gets a fail-closed
result today by accident of bash's own behavior, but no test currently
pins that this stays true, and the exit code is not the gate's contract
(`gate_deny` semantics = exit 2) — so a future change to the preamble
(e.g. adding a line between the source and `gate_trap_fail_closed` that
tolerates the failure) could silently regress this to fail-open with
nothing catching it.

## Confirmed clean — no fix needed

- **hooks.json matcher / code tool-coverage parity (issue #16 req. 2)**:
  all four `hooks.json` register `"matcher": "Write|Edit|MultiEdit"`; all
  four gate scripts' Python payload checks `tool in ("Write", "Edit",
  "MultiEdit")` verbatim (confirmed by direct grep across all four
  scripts). Full parity already holds; no drift found.
- **README / manifest ghost files, old role names (issue #16 req. 4)**:
  read all five READMEs (top-level + four gate plugins) end to end
  against `find <dir> -type f` for each plugin directory. Every file each
  README names exists; no path is named that isn't on disk. No occurrence
  of a pre-issue-10 role name, a retired filename (`record-fields-gate.sh`
  is mentioned only to explain why it has *no* home in this repo, not
  claimed to exist here), or other stale reference was found. This
  requirement is already satisfied by the issue #13 delivery; the
  proposal below does not reopen it, only re-confirms it as a phase-2
  verification step (a regression here would be new, not carried over).

## Scout-brief: skip record

Scouting skipped. This work is a closed defect-remediation pass against
an already-adopted internal standard (core's gate-house standard, issue
#72/#75, and this role's own accepted issue #13 proposal) — the fixes
(whole-cell header match, one added test case, one added test group) have
no external-facing or product-design axis to compare against; the "spec
literally leaves no design decision open" skip condition applies once the
governing shape (core's `gate-lib.py`/test harness) is read, which this
survey did. The one place with real design latitude — how to define
"whole-cell match" precisely enough to still allow "Downstream Link" for
the Downstream Link column — is resolved directly from this repo's own
already-adopted D2 language (`docs/issue-13/proposals/requirements-
engineering-gate-a-plus.md` line ~80: "matched as a whole cell") in the
proposal below, not from external research.
