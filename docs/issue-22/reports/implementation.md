---
code_under_review:
  - gates/test_env_resolve.py
  - gates/test_test_env_resolve.py
  - tests/run-gate-tests.sh
  - req-id-gate/tests/req-id-gate-test.sh
  - traceability-matrix-gate/tests/traceability-matrix-gate-test.sh
  - ambiguity-resolution-gate/tests/ambiguity-resolution-gate-test.sh
  - proposal-discipline-gate/tests/proposal-discipline-gate-test.sh
  - docs/specs/test-env-resolution.md
type: feature
breaking: false
verdict: pass
loop_state: landed
---

# Issue-22 phase 2 record — adopt test-env resolution convention

Subject: issue-22

## What was done

Executed `docs/issue-22/proposals/test-env-resolution-adoption.md`
(approved via the exact-string issue comment
`APPROVE issue-22/implementation` in single-account mode), based on
`docs/issue-22/reports/implementation/survey.md`:

1. Vendored `gates/test_env_resolve.py` and `gates/test_test_env_resolve.py`
   verbatim from on-the-record (`gh api
   repos/tokenmaxxxer/on-the-record/contents/gates/...`) into this repo's
   `gates/`.
2. In each of the four plugin test scripts
   (`req-id-gate/tests/req-id-gate-test.sh`,
   `traceability-matrix-gate/tests/traceability-matrix-gate-test.sh`,
   `ambiguity-resolution-gate/tests/ambiguity-resolution-gate-test.sh`,
   `proposal-discipline-gate/tests/proposal-discipline-gate-test.sh`):
   added a preamble, before any hook subprocess runs, that shells out to
   `python3 -m gates.test_env_resolve "$ROOT/../../core"
   "$ROOT/../../../core"`; on exit `75` the script itself exits `75`
   immediately (SKIP, message already on stderr from the resolver); on
   exit `0` the resolved path is exported as `CLAUDE_PLUGIN_ROOT_CORE`
   for every subsequent hook invocation. Comment references
   `docs/specs/test-env-resolution.md` and `#551`.
3. Rewrote each suite's `missing-core` case: it now asserts the SKIP
   contract (exit `75`) directly against
   `python3 -m gates.test_env_resolve` called with two nonexistent
   candidate paths and `CLAUDE_PLUGIN_ROOT_CORE` unset
   (`env -u CLAUDE_PLUGIN_ROOT_CORE`), rather than against the hook
   subprocess.
4. `tests/run-gate-tests.sh` now tallies a sub-suite's exit `75` as a
   distinct `skip` count (not folded into `fail=1`) and reports it in
   its final summary line.
5. Copied `docs/specs/test-env-resolution.md` from on-the-record into
   this repo's own `docs/specs/`.

Verified: `bash tests/run-gate-tests.sh` with `CLAUDE_PLUGIN_ROOT_CORE`
set to the real core checkout still reports `28 passed, 0 failed` /
`24 passed, 0 failed` / `15 passed, 0 failed` / `15 passed, 0 failed`
(82 total, 0 failed, matching pre-change) plus `0 suite(s) skipped`; the
same command with `env -u CLAUDE_PLUGIN_ROOT_CORE` (no sibling `core`
checkout reachable) has all four suites print the SKIP message and exit
`75`, tallied as `4 suite(s) skipped`, overall exit `0` — zero
misleading pass/fail lines. `python3 -m pytest
gates/test_test_env_resolve.py -q` passes (7 passed). `grep -rl
test-env-resolution` over the five write-set scripts/harness finds all
five.

## Why

Issue #22 asks this rulebook to adopt the canonical test-env resolution
convention landed at on-the-record `docs/specs/test-env-resolution.md`
(issue #551) so gate-test scripts SKIP (exit 75) outside the spawn env
instead of silently misreporting `deny`-expected cases as passing when
the hook under test never ran.

## Upstream basis

`docs/issue-22/proposals/test-env-resolution-adoption.md`

## What did not work

None.

## Open findings

Before-landing warrant hunt (stance 2, `docs/reports/2026-08-09-hunt-test-env-resolution-adoption.md`)
found that a stale `gates/__pycache__/*.pyc` can mask a subsequently
corrupted `gates/test_env_resolve.py` — `python3 -m gates.test_env_resolve`
serves cached bytecode instead of re-reading a broken source file, so the
SKIP/exit-75 path keeps reporting cleanly even though the source is now
unreadable. This is inherent CPython bytecode-cache behavior applying to
any vendored module, not a regression this proposal's changes introduce,
and it does not affect the acceptance checks (SKIP contract and zero
misleading pass/fail both hold on every checkout tested here, which has
no stale `__pycache__/` checked in). Not fixed in this phase — out of
scope per the proposal's "Out of scope" (`gates/test_env_resolve.py`
vendored verbatim, no local hardening beyond that). Left for a follow-up
issue if judged worth the churn (e.g. `.gitignore`'ing `gates/__pycache__/`
or invoking with `python3 -B`).

