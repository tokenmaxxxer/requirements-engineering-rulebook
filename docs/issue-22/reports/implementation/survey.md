Subject: issue-22

# Current-state survey

## The convention (on-the-record, docs/specs/test-env-resolution.md, issue #551)

Fetched via `gh api repos/tokenmaxxxer/on-the-record/contents/docs/specs/test-env-resolution.md`
(this rulebook has no local clone of on-the-record and the repo is not a
network-fetch target per the convention's own "never clones over the
network" rule for the module itself — only the doc text was read, not
vendored as a live dependency).

Resolution order:
1. `$CLAUDE_PLUGIN_ROOT_CORE`, if set and it contains a non-empty
   `hooks/lib/gate-lib.sh`.
2. First caller-supplied sibling-checkout candidate containing the same
   file.
3. Otherwise SKIP (not fail): print
   `SKIP: core plugin unreachable — unverifiable outside spawn env` to
   stderr, exit `75` (`EX_TEMPFAIL`) — distinct from a gate's own
   `0`/`1`/`2` exits.

Reference implementation: `gates/test_env_resolve.py` in the on-the-record
repo, exposing `resolve_core(env, candidates) -> ResolveResult(path, skip,
message)` and a CLI (`python3 -m gates.test_env_resolve <candidates...>`)
that prints the resolved path on exit 0 or the SKIP message on exit 75.
Bash consumers are told to shell out to that CLI and branch on exit code.

## This repo's test scripts (the write set)

- `tests/run-gate-tests.sh` (30 lines) — aggregator, `bash`s the four
  suites below and ORs their exit codes.
- `req-id-gate/tests/req-id-gate-test.sh` (211 lines)
- `traceability-matrix-gate/tests/traceability-matrix-gate-test.sh` (236 lines)
- `ambiguity-resolution-gate/tests/ambiguity-resolution-gate-test.sh` (126 lines)
- `proposal-discipline-gate/tests/proposal-discipline-gate-test.sh` (159 lines)

Each of the four suite scripts drives its plugin's hook
(`<plugin>/hooks/<plugin>.sh`) as a real subprocess via a `run()`/`report()`
harness, maps hook exit code `0/2/other` to `allow/deny/exit-N`, and
compares against an expected verdict. None of the four currently resolves
core explicitly — they rely on the hook's own internal fallback:

```sh
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/gate-lib.sh" \
  || { echo "...: cannot source gate-lib.sh" >&2; exit 2; }
```
(identical pattern in all four hooks: `req-id-gate/hooks/req-id-gate.sh`,
`traceability-matrix-gate/hooks/traceability-matrix-gate.sh`,
`ambiguity-resolution-gate/hooks/ambiguity-resolution-gate.sh`,
`proposal-discipline-gate/hooks/proposal-discipline-gate.sh`).

## The bug this issue targets

Confirmed by direct reproduction: this checkout has no `../../core`
sibling relative to any hook, and outside the spawn session
`CLAUDE_PLUGIN_ROOT_CORE` is unset. In that state every hook invocation's
`source` fails and the hook exits `2` — which the test harness's
`rc=2 -> got=deny` mapping reads as a real "deny" verdict. Every test case
whose expected verdict is `deny` (the majority in all four suites) would
then report `ok` even though the gate's actual logic never ran; only
`allow`-expected cases would visibly fail. This is exactly the "misleading
failure" (here: a misleading pass) the convention exists to remove. Each
suite already has one explicit `missing-core` case
(`CLAUDE_PLUGIN_ROOT_CORE` pointed at a bad path, expecting `deny`) that
happens to encode the same collision on purpose — that case's assertion
becomes meaningless once the fix is applied and needs to change to expect
the SKIP contract instead, everywhere core is genuinely unreachable.

In the current spawn session, `CLAUDE_PLUGIN_ROOT_CORE` IS set (to
`/home/jwjung/.claude/plugins/marketplaces/tokenmaxxxer/runs/rulebooks/tokenmaxxxer-core/core`,
which contains `hooks/lib/gate-lib.sh`), so `bash tests/run-gate-tests.sh`
passes 100% today (verified: `30 passed, 0 failed` combined) — the bug
only shows on a plain checkout outside spawn, matching the issue title.

## Python availability

`python3` is already an existing soft dependency of this repo's test
scripts (`req-id-gate-test.sh` shells out to `python3 -c 'import json...'`
for JSON-string encoding), so adding a `python3 -m gates.test_env_resolve`
call does not introduce a new interpreter dependency — only a new vendored
module.

## Alternatives considered for how to bring the resolver into this repo

1. **Vendor `gates/test_env_resolve.py` verbatim** (matches the doc's own
   "Bash test runner" adoption recipe exactly: `python3 -m
   gates.test_env_resolve <candidates...>`, branch on exit code).
2. **Re-implement the same resolution order in pure bash** inside a
   shared `tests/lib/resolve-core.sh`, sourced by all five scripts —
   avoids depending on the exact on-the-record module contents staying in
   sync, but forks the canonical logic into a second implementation that
   can drift from the convention's reference module.
3. **Do nothing until on-the-record ships this as an installable
   package** — rejected outright: the issue asks for adoption now, not a
   deferral, and the doc's "Out of scope" line explicitly assigns
   per-repo adoption to each repo's own issue/PR (i.e. this one).

## Existing empty-state precedent in this repo

`ambiguity-resolution-gate-test.sh` and the others already print `ok`/
`FAIL` lines per case and a final passed/failed tally with a non-zero
exit on any failure — the aggregator (`tests/run-gate-tests.sh`) already
ORs sub-suite exit codes. A SKIP outcome needs a third state distinct
from both, propagated through the aggregator without being read as
either "all passed" or "something failed".
