# handbook: gate test harness

Current state. Edited from now on to stay true.

`tests/run-gate-tests.sh` (repo root) runs every enforcement plugin's own
test file in this rulebook and aggregates pass/fail. It does not contain
gate logic itself — each plugin owns its own test file under
`<plugin>/tests/<plugin>-test.sh`; this script only calls them in sequence
and exits nonzero if any suite fails.

Run it: `bash tests/run-gate-tests.sh` from the repo root.

Current suites (issue #10, mandatory cases expanded issue #13 gate A+
remediation — Edit-`replace_all`, MultiEdit-mixed-`replace_all`,
malformed-JSON x3, kill-switch-unrecognized-stays-active, absolute-path,
`./`-prefixed-path, plus each gate's own regression case per
`docs/issue-13/proposals/requirements-engineering-gate-a-plus.md`; issue
#16 gate A+ final closeout added a `missing-core` case — `CLAUDE_PLUGIN_ROOT_CORE`
pointed at a nonexistent path, per landed core canon (tokenmaxxxer-core
issue #75) — to all four suites, plus a `d9-resource-not-source` regression
case to traceability-matrix-gate and a plain-`Edit`-allow case to
proposal-discipline-gate):

- `req-id-gate/tests/req-id-gate-test.sh` — 17 cases
- `traceability-matrix-gate/tests/traceability-matrix-gate-test.sh` — 17 cases
- `ambiguity-resolution-gate/tests/ambiguity-resolution-gate-test.sh` — 15 cases
- `proposal-discipline-gate/tests/proposal-discipline-gate-test.sh` — 15 cases

A new plugin's test file must be added to the `SUITES` array in
`tests/run-gate-tests.sh` in the same commit that adds the plugin.

## Test-env resolution (issue #22, on-the-record #551)

Each of the four suite scripts vendors and invokes
`gates/test_env_resolve.py` (verbatim from on-the-record, per
`docs/specs/test-env-resolution.md`) before any hook subprocess runs:
`python3 -m gates.test_env_resolve "$ROOT/../../core" "$ROOT/../../../core"`.
If the resolver exits `75` (core unreachable — no `CLAUDE_PLUGIN_ROOT_CORE`
and no sibling `core` checkout at the candidate paths), the suite script
itself exits `75` immediately with the resolver's SKIP message already on
stderr, running zero test cases. If it exits `0`, the resolved path is
exported as `CLAUDE_PLUGIN_ROOT_CORE` for every hook invocation in that
script. Each suite's `missing-core` case now asserts the SKIP contract
directly against the resolver (bogus candidates, `CLAUDE_PLUGIN_ROOT_CORE`
unset) rather than against the hook subprocess.

`tests/run-gate-tests.sh` tallies a sub-suite's exit `75` as a distinct
`skip` count, separate from `fail`, and reports it in its summary line.
Outside the spawn env (no core reachable), a full run of
`bash tests/run-gate-tests.sh` therefore exits `0` with all four suites
reported as skipped, rather than misreporting `deny`-expected cases as
passing.
