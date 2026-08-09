---
proposal: docs/issue-22/proposals/test-env-resolution-adoption.md
---

# Hunt record — test-env-resolution-adoption

## after-proposal — stance 1: assume this change and another plugin's rule cancel each other — find the pair.

Verdict: NO FINDING
Seed: git diff --stat HEAD~1 HEAD (docs/issue-22/proposals/test-env-resolution-adoption.md, docs/issue-22/reports/implementation/survey.md — 231 insertions, docs-only)
cap_seconds: 60
tier: default
diff_stat_lines: 2 files, 231 insertions(+)
started_at: 2026-08-09T09:42:23+09:00
ended_at: 2026-08-09T09:44:00+09:00

Checked proposal-discipline-gate.sh (the only PreToolUse gate in this repo that inspects
Write/Edit/MultiEdit file_path): its PROPOSAL_RE only matches
docs/issue-[0-9]+/proposals/*requirements-engineering*.md. The phase-2 targets this
proposal names -- gates/test_env_resolve.py, gates/test_test_env_resolve.py,
tests/run-gate-tests.sh, and the four gate-test scripts under *-gate/tests/*-test.sh --
fall outside that regex, so this gate would not fire on them at all (not cancel, not
silently block). ambiguity-resolution-gate.sh, traceability-matrix-gate.sh and
req-id-gate.sh target other content patterns entirely (ambiguity markers, traceability
matrices, req-id tags), unrelated to a vendored Python resolver or shell-script edits.
scope-gate.sh and survey-order-gate.sh, named in the stance as candidates, do not exist
anywhere in this repo (find . -iname '*gate*.sh' lists only the four gates above). No
pair of rules in this repo currently cancels or blocks the proposal's planned phase-2
writes; ran out of cap time before checking whether gates/ (singular top-level dir the
proposal assumes) existing-vs-absent is itself a defect, so that thread is unexplored,
not exonerated.

## before-landing — stance 2: assume this guard goes silent when its own input is malformed — make it go silent

Verdict: FINDING — a corrupted/unreadable gates/test_env_resolve.py is masked by Python's bytecode cache, so the resolver silently keeps returning its last-good SKIP/exit-75 result instead of surfacing the breakage
Kind: silent-failure
Seed: gates/test_env_resolve.py, req-id-gate/tests/req-id-gate-test.sh preamble (lines ~9-15), same preamble pattern in traceability-matrix-gate/tests/, ambiguity-resolution-gate/tests/, proposal-discipline-gate/tests/
cap_seconds: 120
tier: default
diff_stat_lines: gates/test_env_resolve.py (new, 78 lines), gates/test_test_env_resolve.py (new, vendored), req-id-gate-test.sh/traceability-matrix-gate-test.sh/ambiguity-resolution-gate-test.sh/proposal-discipline-gate-test.sh (preamble ~8 lines each), tests/run-gate-tests.sh (skip tally)
started_at: 2026-08-09T09:50:00+09:00
ended_at: 2026-08-09T10:05:00+09:00

### Reproduce
```
cd <repo root>
unset CLAUDE_PLUGIN_ROOT_CORE

# step 1: a normal run — this is what CI/dev workspaces do on every invocation,
# and it leaves gates/__pycache__/test_env_resolve.cpython-310.pyc behind
bash req-id-gate/tests/req-id-gate-test.sh
echo "rc1=$?"          # -> SKIP message, rc1=75 (correct)

# step 2: the module source becomes unreadable/corrupted in the SAME checkout
# (bad merge, permissions regression, disk fault, partial checkout overwrite —
# anything that makes the .py unreadable while the stale .pyc survives)
chmod 000 gates/test_env_resolve.py

# step 3: re-run the identical suite, same checkout, no code changes elsewhere
bash req-id-gate/tests/req-id-gate-test.sh
echo "rc2=$?"
```

### Observed
```
--- step 1 ---
SKIP: core plugin unreachable — unverifiable outside spawn env
rc1=75
test_env_resolve.cpython-310.pyc
--- step 2/3 ---
SKIP: core plugin unreachable — unverifiable outside spawn env
rc2=75
```
Identical output and exit code to the healthy run — no indication whatsoever
that `gates/test_env_resolve.py` is now unreadable (`chmod 000`). Control
verified: with `gates/__pycache__` removed first, the same `chmod 000` on the
same file produces `PermissionError: [Errno 13] Permission denied` on stderr
and the preamble's own guard correctly turns it into
`req-id-gate-test.sh: test-env resolution failed unexpectedly (rc=1)` /
`exit 2` — i.e. the preamble's rc-checking logic is fine in isolation, but
`python3 -m gates.<module>` happily serves `__import__`-cached bytecode
instead of re-reading a since-broken source file, and nothing in the preamble,
in `gates/test_env_resolve.py`, or in `tests/run-gate-tests.sh` invalidates or
disables that cache (no `-B`/`PYTHONDONTWRITEBYTECODE`, no `.gitignore` entry
even ignoring `__pycache__/` in the repo to flag it as throwaway). Any CI
runner or dev workspace that reuses a checkout across two invocations of the
gate-test suites (the overwhelmingly common case — `tests/run-gate-tests.sh`
itself invokes all four suites back-to-back in one process, populating the
cache before any of them could hit this) will mask exactly the malformed-input
scenarios this stance targets: a resolver whose own file is broken keeps
reporting "SKIP: core plugin unreachable" (or, symmetrically, a stale
"resolved" result) as if nothing changed.

### Expected
Either the invocation disables bytecode caching for this test-only resolver
(`python3 -B -m gates.test_env_resolve ...`, or `PYTHONDONTWRITEBYTECODE=1`),
or `gates/__pycache__/` is excluded/cleaned so a broken source file cannot be
shadowed by a prior run's compiled bytecode — so that corrupting or breaking
`gates/test_env_resolve.py` is guaranteed to surface as the preamble's own
"test-env resolution failed unexpectedly" exit 2, in every checkout, not only
in checkouts that happen to have no `__pycache__` yet.
