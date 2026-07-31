# Scout brief — enforcement mechanisms for adopted methodology (issue #10)

Phase 1 only. This brief backs
`docs/issue-10/proposals/requirements-engineering-enforcement.md`.

## Scope of the sweep

Question: given the requirements-engineering methodology already adopted
in `docs/issue-1/proposals/requirements-engineering.md` and reflected in
this repo's `README.md` "Doctrine" section, what is the right shape for a
machine-enforced gate that turns "produces: structured requirements doc,
traceability matrix, ambiguity list resolved" from a documented norm into
something a `PreToolUse` hook actually checks?

**Web sweep: skipped.** This environment's Bash/WebSearch tools are
sandboxed to the repo working tree and package registries; no general web
search or fetch capability was available in this session. Per the
scouting protocol's own allowance, this is a documented skip, not a
silent omission — internal prior art (below) is used as the primary
exemplar instead, and it is unusually strong prior art: two sibling
rulebooks in the same monorepo family already solved this exact problem
for their own roles.

## Round 1 — internal prior art (this monorepo family)

Searched (via filesystem, not web): sibling rulebook checkouts present on
this machine under `~/tokenmaxxxer/rulebooks/`.

1. **`pricing-rulebook/pricing/hooks/methodology-gate.sh`** (~230 lines) —
   a `PreToolUse` gate on `Write|Edit|MultiEdit` that resolves the
   post-write content of any file matching the role's own proposal/record
   path patterns (`docs/issue-<n>/proposals/*pricing*.md`,
   `docs/issue-<n>/reports/pricing.md`), reconstructs the resulting text
   for `Write`/`Edit`/`MultiEdit` inputs, and denies (exit 2) unless every
   required methodology element (method named, family named when
   applicable, inputs-needed stated, gate-check result present, labeled
   numbers, residual list) is present as a substring/pattern match. It is
   explicitly named in issue #10's own body as the pattern to imitate.
2. **`implementation-rulebook/coding/hooks/coding-progress-gate.sh`**
   (~180 lines) — the sequencing/state-tracking exemplar: gates `git
   commit` (via Bash matcher), reads a companion role's record
   (`verify.md`), parses inline `finding` blocks for
   `severity: blocking` + `addressed_to: coding`, and denies the commit
   unless coding's own record shows a `resolved_findings` entry *and* the
   verifier's `loop_state` is `cleared`. This is the closest internal
   example of enforcing an ordering constraint (verify before commit)
   across two records via state fields rather than free-text policy.
3. **`implementation-rulebook/tests/run-gate-tests.sh`** — the gate-test
   exemplar: a single bash harness that spins up a throwaway git repo per
   case, feeds a synthetic PreToolUse JSON payload on stdin to the gate
   script under test, reads its exit code (0=allow, 2=deny, else=internal
   error), and reports pass/fail. No test framework dependency; the gate
   scripts are executed as real subprocesses, not mocked.

## Judgment

All three are top-tier and directly decision-relevant: they are the exact
rigor bar issue #10 names ("hook machine", "methodology-gate.sh ...
reference"), authored for sibling roles under the same contract v3, using
the same hook JSON event shape this repo's `directive.sh` already
consumes. No further stage was needed — round 1 already saturated the
decision-relevant question (round 2 would only turn up more instances of
the same pattern in yet more sibling rulebooks, which would not change
the design). Stopped after 1 round, well under the 3-minute/5-stage cap,
on saturation grounds.

## Extraction

- **Must-bes**: (1) fail-closed trap-at-top (`trap __fc EXIT` remapping
  any non-0/non-2 exit to 2) so a script bug denies rather than silently
  allows; (2) resolve the *resulting* text of a Write/Edit/MultiEdit
  before judging it, not just the diff fragment, since Edit/MultiEdit
  tool_input never contains the whole file; (3) a path-pattern allowlist
  so the gate only fires on this role's own write surfaces and no others
  (never globally on every Write); (4) a documented kill switch
  (`<ROLE>_METHODOLOGY_GATE_OFF=1`) for legitimate override during
  migration/debugging, consistent with core canon's own kill-switch
  convention.
- **Performance axes**: (a) precision of the "produces" check — string/
  regex heuristics on rendered text, not full NLP, so it's fast and
  auditable; (b) fail-closed correctness — every malformed-input branch
  denies, never silently passes; (c) test coverage per required element,
  each element has both an allow-path and a deny-path case in the gate
  test suite.
- **Pattern to adopt**: pricing's per-element `missing.append(...)` +
  single combined deny message naming every missing element at once
  (not one deny per element) — cheaper for the agent under gate to fix in
  one pass, and mirrors how record-fields-gate.sh already reports.
- **Pattern to skip**: coding-progress-gate's cross-role state-tracking
  machinery (reading a *different* role's record for a blocking finding)
  is unnecessary for this role's phase-2 producing act, because
  requirements-engineering's `produces` elements (requirements doc,
  traceability matrix, ambiguity list) are three sections of the *same*
  single record, not a two-role sequencing problem — so the ordering
  constraint this role actually needs (survey → adopted norm → citation,
  within one proposal) is checkable by string presence within one file,
  not by cross-file `loop_state` polling. Adopting the heavier machinery
  here would be over-fit to a mechanism this role's shape doesn't need.
- **Gap line**: current requirements-engineering state (README.md
  Doctrine + `docs/issue-1/proposals/requirements-engineering.md`) already
  meets the field's documentation bar (a schema is named, precisely) but
  meets *zero* of the field's enforcement bar — there is no `PreToolUse`
  hook in `requirements-engineering/hooks/hooks.json` beyond
  `directive.sh` on `SessionStart`, and issue #2's own conversion
  explicitly logged this as an open, unowned gap ("this role's own
  content-level requirements gate... has no home in canon and is out of
  scope"). The field (as represented by the two sibling exemplars above)
  has already closed this exact gap for pricing and coding; this proposal
  closes it for requirements-engineering using the same shape.

## Sources

- `/home/jwjung/tokenmaxxxer/rulebooks/pricing-rulebook/pricing/hooks/methodology-gate.sh` (local checkout, read directly)
- `/home/jwjung/tokenmaxxxer/rulebooks/pricing-rulebook/pricing/hooks/hooks.json`
- `/home/jwjung/tokenmaxxxer/rulebooks/implementation-rulebook/coding/hooks/coding-progress-gate.sh`
- `/home/jwjung/tokenmaxxxer/rulebooks/implementation-rulebook/tests/run-gate-tests.sh`
- This repo: `docs/issue-1/proposals/requirements-engineering.md`, `docs/issue-2/proposals/canon-reference-conversion.md`, `docs/issue-2/reports/requirements-engineering.md`, `README.md` (Doctrine section)
- GitHub issue #10 body (`gh issue view 10`), which itself names
  `pricing-rulebook`'s `methodology-gate.sh` as the reference pattern —
  treated as a primary source since it directs this proposal's shape.

Web search/fetch: not attempted beyond the above — no network tool
available in this session (see "Web sweep: skipped" above).
