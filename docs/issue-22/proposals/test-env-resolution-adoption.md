Subject: issue-22

status: proposed
files:
  - gates/test_env_resolve.py
  - gates/test_test_env_resolve.py
  - tests/run-gate-tests.sh
  - req-id-gate/tests/req-id-gate-test.sh
  - traceability-matrix-gate/tests/traceability-matrix-gate-test.sh
  - ambiguity-resolution-gate/tests/ambiguity-resolution-gate-test.sh
  - proposal-discipline-gate/tests/proposal-discipline-gate-test.sh
  - docs/specs/test-env-resolution.md

## Request

Adopt the canonical test-env resolution convention landed at on-the-record
`docs/specs/test-env-resolution.md` (issue #551) in this rulebook's
gate-test scripts: outside the spawn env (no `CLAUDE_PLUGIN_ROOT_CORE`, no
reachable core checkout) every script should exit via the convention's
SKIP contract — explicit stderr message, exit `75` — instead of silently
misreporting `deny`-expected cases as passing when the hook under test
never actually ran. No assertion that runs when core IS reachable may
weaken.

## Constraints

- Zero misleading verdicts outside spawn: the SKIP path must trigger
  before any hook subprocess is invoked, not after a first false pass.
- All currently-passing assertions (`30 passed, 0 failed` today, verified
  with core reachable) must still pass unchanged when core is reachable.
- Every script that resolves core must reference the convention
  (`grep -r test-env-resolution` must find it), per the issue's own
  acceptance check.
- SKIP is exit `75`, distinct from the harness's existing `0`/`1`/`2`
  gate-verdict exits (already reserved in every hook and test script).
- No network fetch as part of the canonical resolution path (per the
  convention doc itself).
- A script's own real defect must still surface as a finding, never
  masked by SKIP (issue's empty-state rule).

## Rationale

**Vendor `gates/test_env_resolve.py` verbatim from on-the-record and
invoke it as `python3 -m gates.test_env_resolve <candidates...>`
per-script** (chosen) **vs. re-implementing the same resolution order in
a hand-written bash function** (rejected): the survey
(`docs/issue-22/reports/implementation/survey.md`) found `python3` is
already a soft dependency of these test scripts (`req-id-gate-test.sh`
already shells out to `python3 -c` for JSON encoding), so vendoring adds
no new interpreter dependency — only a file. A bash re-implementation
would fork the canonical resolution logic (env-var check, non-empty-file
check, candidate list, SKIP+75) into a second hand-maintained copy that
can silently drift from the convention's reference module, which is
exactly the "consumers hand-rolling their own" problem the convention doc
says it exists to end. Vendoring the reference module and its own test
file (`gates/test_test_env_resolve.py`) keeps this repo's copy checkable
against upstream by diff, and it is also the literal "Bash test runner"
adoption recipe the convention doc itself prescribes.

**Deferring adoption until on-the-record ships an installable package**
was also considered and rejected: the convention doc's own "Out of
scope" section assigns per-repo adoption to each repo's own issue/PR —
this issue is that assignment, not optional follow-up work.

## What will be done

- Vendor `gates/test_env_resolve.py` and `gates/test_test_env_resolve.py`
  verbatim from the on-the-record repo (as fetched via `gh api
  repos/tokenmaxxxer/on-the-record/contents/...`, no live network
  dependency at test-run time) into this repo's own `gates/` directory.
- In each of the four plugin test scripts
  (`req-id-gate/tests/req-id-gate-test.sh`,
  `traceability-matrix-gate/tests/traceability-matrix-gate-test.sh`,
  `ambiguity-resolution-gate/tests/ambiguity-resolution-gate-test.sh`,
  `proposal-discipline-gate/tests/proposal-discipline-gate-test.sh`): at
  the top, before any hook subprocess runs, shell out to `python3 -m
  gates.test_env_resolve <candidate paths>` (candidates: `../../core`,
  `../../../core` — the sibling-checkout shapes these scripts' own
  hooks already default to) from the repo root; on exit `75`, print the
  SKIP message and exit `75` immediately without running any test case;
  on exit `0`, capture the resolved path on stdout and export it as
  `CLAUDE_PLUGIN_ROOT_CORE` for every subsequent hook invocation in that
  script (replacing reliance on the hook's own internal fallback).
  Reference the convention doc inline in a comment
  (`docs/specs/test-env-resolution.md`, `#551`) so the acceptance grep
  finds it.
- Rewrite each suite's existing `missing-core` case: it currently
  expects `deny` from a `CLAUDE_PLUGIN_ROOT_CORE` pointed at a
  nonexistent path, which after this change resolves as a genuine SKIP
  condition — keep the case, but repoint its assertion at the SKIP
  contract (exit `75`) via a direct call to the resolver with a bad
  candidate, rather than at the hook subprocess.
- Update `tests/run-gate-tests.sh` to treat a sub-suite's exit `75` as a
  distinct SKIP outcome in its own tally (not folded into `fail=1`),
  and report it as such in its final summary line.
- Copy `docs/specs/test-env-resolution.md` into this repo's own
  `docs/specs/` (matching the "specs describe the system" precedent
  already used for `docs/specs/approvers.md` /
  `docs/specs/record-fields-terminal-states.json`) so the convention this
  repo now depends on has a durable in-repo reference, not only a memory
  of having read it once from on-the-record.

## Out of scope

- Changing the hooks themselves (`*/hooks/*.sh`) — they already run
  correctly inside the real spawn env where `CLAUDE_PLUGIN_ROOT_CORE` is
  always set by the harness; this issue is about the *test* scripts only,
  per the issue's own scoping ("this rulebook's gate-test scripts").
- Any change to gate assertion logic/content beyond the `missing-core`
  case's expected verdict.
- Keeping `gates/test_env_resolve.py` in sync with future upstream
  changes automatically — future convention revisions are a follow-up
  vendoring pass, not addressed here.

## How you'll know it worked

- `bash tests/run-gate-tests.sh` with `CLAUDE_PLUGIN_ROOT_CORE` unset and
  no sibling `core` checkout present exits via the SKIP contract (exit
  `75`, explicit message on stderr) with zero misleading pass/fail lines.
- The same command with `CLAUDE_PLUGIN_ROOT_CORE` set to a real core
  checkout (the current spawn-env condition) still reports `30 passed, 0
  failed` as it does today.
- `grep -rl test-env-resolution` over the repo's test scripts returns all
  five files in the write set above.
- `python3 -m pytest gates/test_test_env_resolve.py -q` passes.
