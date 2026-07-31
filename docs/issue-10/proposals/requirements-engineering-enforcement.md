# Proposal — requirements-engineering methodology enforcement (issue #10)

**Phase 1 only.** Nothing described here has been executed. Phase 2
(the actual hook/test/agent files) opens only after an account listed in
`docs/specs/approvers.md` approves this PR (contract v3 s19), matching
the issue-1/issue-2/issue-5 precedent in this repo.

- **Survey-basis pointer**: `docs/issue-10/reports/requirements-engineering/survey.md`
- **Scout brief**: `docs/issue-10/reports/requirements-engineering/scout-brief.md`
- **Adopted-norm source (unchanged, not re-derived here)**:
  `docs/issue-1/proposals/requirements-engineering.md`

## Problem / scope

Issue #10: the methodology this role adopted in the prior maturation
round (issue #1) exists only as documentation — a one-line `PRODUCES`
string in `directive.sh` and prose in `README.md`'s Doctrine section.
Sibling rulebooks (`pricing`, `coding`, both in `implementation-rulebook`'s
family) enforce their own adopted methodologies mechanically via
`PreToolUse` gates, state tracking where the methodology has a real
ordering constraint, and gate test suites. This role has none of that.
This proposal designs (not implements) the four elements the issue asks
for, at a level concrete enough that phase 2 can build directly from it.

## (1) Directive deepening

`directive.sh`'s `PRODUCES` line stays as the one-line SessionStart
summary (canon's `core_role_directive` takes four fixed arguments; this
constraint was already surfaced and accepted in issue-2's proposal). What
issue #10 actually asks for — stage/criteria/prohibition detail per facet
— is proposed to live in a new doctrine file,
**`requirements-engineering/hooks/lib/produces-schema.md`** (new,
role-owned; not core canon), read by both the gate script (as the
authoritative "what must be present" checklist a human/agent can also
read) and `README.md` (which currently duplicates this prose and should
instead link to it, to avoid the two drifting apart).

Proposed content shape for `produces-schema.md`, per facet:

### Facet A — Structured requirements doc

- **Stages**: (1) elicitation input identified (a named upstream
  hypothesis/artifact this doc traces from) → (2) each requirement
  drafted with a unique ID → (3) each requirement carries an explicit
  verification condition.
- **Judgment criteria**: an ID is unique within the record (no two
  requirements share `REQ-` numbers); a verification condition is
  "explicit" if it names an observable outcome (Given/When/Then, or a
  bare `Verification:` line with a check a test could run against) —
  a requirement whose only content is a "shall" sentence with no
  condition fails this facet.
- **Prohibitions**: no requirement may appear only in prose without an
  ID; no verification condition may read as a restatement of the
  requirement itself (circularity is a facet failure, judged by the gate
  only insofar as string-detectable — genuine circularity beyond that is
  a human/reviewer judgment call, not machine-enforceable, and the gate
  must not overclaim it can catch every case).
- **Executable level**: machine-checkable via presence-of-pattern (see
  §2) for ID-format and a verification-condition keyword; the
  "is-it-actually-a-good-condition" judgment is not machine-executable
  and is left to the phase-2 human/agent, per the same honesty this
  repo's other gates already practice (e.g. pricing's own docstring:
  it checks presence, not truth).

### Facet B — Traceability matrix

- **Stages**: (1) matrix table exists → (2) all four core columns present
  (ID, Description, Source, Downstream Link) → (3) every requirement ID
  from facet A appears as a row.
- **Judgment criteria**: "exists" = a markdown table (or explicitly
  labeled equivalent) is present under a heading matching
  `traceability matrix` (case-insensitive); row-completeness ("every
  requirement ID appears") is checked by simple ID-membership, not table
  parsing correctness beyond that.
- **Prohibitions**: no row with an empty ID or empty Source cell (per the
  existing adopted-norm text: "No matrix without unique IDs on both ends
  of every row").
- **Executable level**: column-header presence and per-ID row-membership
  are both machine-checkable at the string level (see §2 pseudocode);
  full table-cell parsing (verifying no cell is blank) is a stretch goal
  the gate may implement via a light table-row regex, degrading
  gracefully (skip the check, do not falsely pass or falsely fail) if the
  table isn't parseable as strict markdown.

### Facet C — Ambiguity list, resolved

- **Stages**: (1) an "Ambiguity" section exists (even if empty) →
  (2) each entry states the ambiguous statement + candidate readings →
  (3) each entry states a resolution or an explicit escalation.
- **Judgment criteria**: a record with genuinely zero ambiguities must
  say so explicitly (an empty section header alone does not count —
  per the adopted norm, "must say so explicitly, not omit the section");
  "escalated — unresolved" is an acceptable terminal value for resolution,
  a blank value is not.
- **Prohibitions**: no entry may be silently dropped (i.e., a heading
  present with zero content is a facet failure, not a pass) unless the
  explicit "no ambiguities found" sentence is present.
- **Executable level**: presence of the section heading, presence of
  either an explicit "no ambiguities found"-equivalent sentence or at
  least one entry carrying a resolution keyword, both machine-checkable.

## (2) Methodology gate — design

New file (phase 2, not created in this PR):
**`requirements-engineering/hooks/methodology-gate.sh`**, modeled directly
on `pricing/hooks/methodology-gate.sh` (see scout brief) — same fail-closed
trap-at-top, same stdin JSON payload, same Write/Edit/MultiEdit
result-text reconstruction, same path-pattern scoping, same kill switch
convention. Registered in `requirements-engineering/hooks/hooks.json`
under a new `PreToolUse` block matched on `Write|Edit|MultiEdit`
(hooks.json changes are phase-2, not made in this PR).

### Path scope

```
PROPOSAL_RE = ^docs/issue-[0-9]+/proposals/.*requirements-engineering.*\.md$
RECORD_RE   = ^docs/issue-[0-9]+/reports/requirements-engineering\.md$
```
(mirrors this role's actual write surfaces per `write_scope: []` +
report-only convention; any write outside these two patterns is not this
gate's business — `sys.exit(0)` immediately, same as pricing's gate.)

### Check logic (pseudocode, phase-2 fills in the exact regex)

```
resolve resulting text of the write (Write=content; Edit/MultiEdit=
  reconstruct from current file + old/new string substitution, deny if
  unreconstructable — same as pricing's gate)
low = text.lower()

missing = []

# Facet A — structured requirements doc
if not re.search(r'\bREQ-[0-9A-Za-z]+\b', text):
    missing.append("requirement-id")
elif no requirement-id line is followed (within N lines) by a
     verification-condition marker ("given", "when", "then",
     "verification:", "verification condition"):
    missing.append("verification-condition")

# Facet B — traceability matrix
if not has_any("traceability matrix"):
    missing.append("traceability-matrix-section")
elif matrix section lacks all four column headers
     ("id", "description"/"desc", "source", "downstream"):
    missing.append("traceability-matrix-columns")
elif any REQ-xxx id from facet A is absent from the matrix section text:
    missing.append("traceability-matrix-row-for-<id>")

# Facet C — ambiguity list
if not has_any("ambiguity"):
    missing.append("ambiguity-section")
elif not (has_any("no ambiguities found", "none found", "no ambiguities")
          or has_any("resolution:", "escalated")):
    missing.append("ambiguity-resolution-or-explicit-none")

if this is a PHASE-1 PROPOSAL path (PROPOSAL_RE matched):
    # phase-1's own 7-section norm from docs/issue-1/proposals/
    # requirements-engineering.md (a)
    for section in ["problem", "survey-basis", "adopted norm",
                     "rejected alternative", "plugin-reflection",
                     "verification plan", "status"]:
        if section-heading-or-equivalent not in low: missing.append(section)

if missing: deny("requirements-engineering methodology write is missing "
                  "required element(s): " + ", ".join(missing) + " — per "
                  "docs/issue-1/proposals/requirements-engineering.md, "
                  "requirements-engineering/hooks/lib/produces-schema.md")
else: exit 0
```

This combined-deny-message shape (one deny listing every missing element,
not one deny per element) is the scout brief's "pattern to adopt" from
pricing's gate.

### State tracking — is it needed?

The survey's gap analysis (§4) already flags this as an open question;
this proposal resolves it: **no cross-file state file is needed.** This
role's adopted methodology has exactly one genuine ordering constraint —
"survey → adopted norm with citation → proposal" (from
`docs/issue-1/proposals/requirements-engineering.md` (a) item 1) — but
that ordering is entirely *within a single phase-1 proposal document*
(the same file must contain a Survey-basis pointer section before/
alongside its Adopted-norm section; there is no second role's record to
poll, unlike coding-progress-gate's verify→coding cross-role case). A
single-file presence check (facet + phase-1-section check above) is
therefore sufficient; adopting `coding-progress-gate`'s cross-file
`loop_state` polling machinery here would be over-fit, per the scout
brief's explicit "pattern to skip." If a future issue introduces a real
cross-record ordering need for this role (e.g., a required upstream
record must reach a specific `loop_state` before this role may write),
phase 2 should revisit this decision against that new requirement, not
build it speculatively now.

## (3) Gate tests — design

New file (phase 2, not created in this PR):
**`requirements-engineering/hooks/tests/methodology-gate-test.sh`**,
modeled directly on `implementation-rulebook/tests/run-gate-tests.sh`'s
`run()` helper (throwaway git repo per case, synthetic JSON PreToolUse
payload piped to the gate script as a real subprocess, exit-code
assertion). Proposed case list (allow + deny per facet, per the
performance axis "each element has both an allow-path and a deny-path
case" from the scout brief):

| Case name | Path | Content | Expected |
|---|---|---|---|
| `record-complete` | `docs/issue-7/reports/requirements-engineering.md` | all three facets present, well-formed | allow |
| `record-missing-req-id` | same | no `REQ-` token anywhere | deny (requirement-id) |
| `record-missing-verification` | same | `REQ-1` present, no verification marker nearby | deny (verification-condition) |
| `record-missing-matrix-section` | same | no "traceability matrix" heading | deny (traceability-matrix-section) |
| `record-matrix-missing-column` | same | matrix heading present, missing "Downstream" column | deny (traceability-matrix-columns) |
| `record-matrix-missing-row` | same | matrix present, `REQ-2` from facet A absent from matrix rows | deny (traceability-matrix-row-for-REQ-2) |
| `record-missing-ambiguity-section` | same | no "ambiguity" heading | deny (ambiguity-section) |
| `record-ambiguity-explicit-none` | same | "No ambiguities found." present, no other ambiguity content | allow |
| `record-ambiguity-heading-only` | same | heading present, zero content, no explicit-none sentence | deny (ambiguity-resolution-or-explicit-none) |
| `proposal-all-seven-sections` | `docs/issue-9/proposals/requirements-engineering-x.md` | all 7 phase-1 sections present + facet content | allow |
| `proposal-missing-status-section` | same | 6 of 7 sections, missing Status | deny (status) |
| `foreign-path` | `docs/issue-7/reports/qa.md` | anything | allow (not this gate's business — mirrors pricing's own `foreign-path`-style case and `record-fields-gate.sh`'s existing test) |
| `edit-unreconstructable` | `docs/issue-7/reports/requirements-engineering.md` | Edit with `old_string` not present in current file | deny (cannot determine resulting content — fail closed, mirrors pricing gate's identical branch) |
| `kill-switch-off` | any in-scope path | otherwise-failing content, with `REQUIREMENTS_ENGINEERING_METHODOLOGY_GATE_OFF=1` set | allow (kill switch honored) |

Each case follows `run-gate-tests.sh`'s existing `report()` convention
(want/got comparison, pass/fail tally, non-zero exit if any case fails) so
this new file can be dropped into this repo's own future
`tests/run-gate-tests.sh` (currently nonexistent here; phase 2 must create
it, following the same harness shape as `implementation-rulebook/tests/
run-gate-tests.sh`, not vendoring that file itself — this repo's harness
is new, role-owned code exercising this repo's own gate, structurally
similar by design pattern only).

## (4) Agents / checklists

The phase-1 proposal norm's 7-section requirement (from
`docs/issue-1/proposals/requirements-engineering.md` (a)) is itself a
repeated procedure every future proposal-writing session under this role
must follow. Two options, not resolved here — a genuine open design
question for the approver, since this role currently has zero files
under `agents/`:

- **Option A (checklist only)**: keep it as prose in `README.md` /
  `produces-schema.md`, now backed by the machine gate in §2 (which
  already checks section presence for phase-1 proposals) — no new agent
  file. Lower cost; the gate itself is the enforcement, a human-readable
  checklist is documentation only.
- **Option B (agent file)**: add
  `requirements-engineering/agents/requirements-scout.md` — a short agent
  persona whose job is exactly "before drafting a phase-2 record, confirm
  the upstream hypothesis is named, elicit ambiguities, and draft
  requirement IDs before prose" (i.e., front-loads the facet ordering the
  gate checks after the fact). Modeled in file shape (not content — no
  canon vendoring) on how core's `warrant/agents/warrant-hunter.md`
  convention is referenced by sibling roles per `docs/issue-2/proposals/
  canon-reference-conversion.md` action item 1.

**Recommendation for phase 2 to confirm, not decided in this PR**: Option
A is proposed as sufficient, because the gate in §2 already makes the
7-section/3-facet requirement machine-enforced at write time; an agent
file's marginal value is front-loading (catching the gap before the
write attempt) rather than back-stopping (catching it at the write
attempt), and this role's methodology (per the scout brief's "pattern to
skip" reasoning) does not have a genuinely multi-session repeated hunt
cadence the way core's `warrant-hunter` does. Option B remains available
if the approver judges the front-loading value worth a new agent file.

## Canon-reference discipline (unchanged)

None of the above requires copying core canon content:
- `directive.sh` continues to source `core/hooks/lib/role-directive.sh`
  by reference only (unchanged from the issue-2 conversion).
- The new `methodology-gate.sh` is new role-owned logic — structurally
  patterned after `pricing/hooks/methodology-gate.sh` (a sibling rulebook,
  not core canon) but containing this role's own facet content; it is not
  a vendored copy of anything under `core/hooks/`.
- The new `tests/methodology-gate-test.sh` is new role-owned test code,
  patterned after `implementation-rulebook/tests/run-gate-tests.sh`'s
  harness shape, not copied verbatim.
- Core's existing global gates (`record-fields-gate.sh` et al., firing via
  core's own install per issue-2/issue-5) are untouched and continue to
  check only contract §20's role-agnostic fields; this proposal's new gate
  is additive, checking this role's content-specific facets on top of
  (never instead of) canon's structural check — same relationship
  pricing's gate already has to canon's `record-fields-gate.sh`.

## Verification plan

Phase 2 must, before landing:
1. Create `produces-schema.md`, `methodology-gate.sh`,
   `hooks/tests/methodology-gate-test.sh`, and wire the new `PreToolUse`
   entry into `hooks.json`.
2. Run the new test file and confirm every case in the §3 table passes
   (all-allow and all-deny cases as specified).
3. Run core's own `stub-check.sh` (referenced, not vendored, per issue-5)
   against this role's `hooks/` tree to confirm `directive.sh` remains in
   stub form and no gate-copy drift was introduced.
4. Record the pass/fail output of both runs in
   `docs/issue-10/reports/requirements-engineering.md` (phase-2 output,
   not written in this PR).
5. Confirm the Option A/B agent-file decision (§4) was actually made (not
   left silently unresolved) and recorded.

## Rejected alternatives

- **Vendoring `pricing/hooks/methodology-gate.sh` verbatim and
  parameterizing it** — rejected: the file's method-taxonomy content
  (PSM/conjoint/CBC keyword lists) is pricing-domain-specific; copying the
  file and swapping keywords would still constitute copying a sibling
  rulebook's file wholesale rather than writing role-owned logic, and
  issue #10's own constraint ("캐논 스크립트는 참조만·복사 금지") extends
  in spirit to not vendoring a sibling rulebook's role-specific gate
  either — the shape (fail-closed structure, path scoping, kill switch)
  is reused as a *pattern*, not as a *file*.
- **A single monolithic content check merged into canon's
  `record-fields-gate.sh`** — rejected per issue-2's own explicit finding:
  canon's gate is role-agnostic by design; folding role-specific facet
  checks into it would require every other role's canon-referencing
  rulebook to inherit requirements-engineering-specific regexes, which is
  exactly the coupling issue-2 flagged as out of scope.
- **Full state-tracking machine (mirroring coding-progress-gate.sh) for
  this role** — rejected per §2's "State tracking — is it needed?"
  analysis: no genuine cross-file ordering constraint exists yet for this
  role; building the heavier machine now would be speculative
  over-engineering against a requirement this role doesn't currently have.

## Status

Proposal only. Awaiting Approve from an account listed in
`docs/specs/approvers.md` before phase 2 (creating
`produces-schema.md`, `methodology-gate.sh`, the gate test file, the
`hooks.json` wiring, and the agents/checklist decision) begins.
