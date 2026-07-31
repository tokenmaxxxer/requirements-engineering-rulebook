# handbook: gate test harness

Current state. Edited from now on to stay true.

`tests/run-gate-tests.sh` (repo root) runs every enforcement plugin's own
test file in this rulebook and aggregates pass/fail. It does not contain
gate logic itself — each plugin owns its own test file under
`<plugin>/tests/<plugin>-test.sh`; this script only calls them in sequence
and exits nonzero if any suite fails.

Run it: `bash tests/run-gate-tests.sh` from the repo root.

Current suites (issue #10):

- `req-id-gate/tests/req-id-gate-test.sh` — 6 cases
- `traceability-matrix-gate/tests/traceability-matrix-gate-test.sh` — 6 cases
- `ambiguity-resolution-gate/tests/ambiguity-resolution-gate-test.sh` — 6 cases
- `proposal-discipline-gate/tests/proposal-discipline-gate-test.sh` — 5 cases

A new plugin's test file must be added to the `SUITES` array in
`tests/run-gate-tests.sh` in the same commit that adds the plugin.
