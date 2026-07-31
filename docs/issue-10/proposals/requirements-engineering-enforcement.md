# Proposal — requirements-engineering methodology enforcement (issue #10)

**Phase 1 only.** Nothing described here has been executed. Phase 2
(the actual plugin files) opens only after an account listed in
`docs/specs/approvers.md` approves this PR (contract v3 s19), matching
the issue-1/issue-2/issue-5 precedent in this repo.

**Revision note**: this proposal was rewritten per the approver's 요구
정정 comment on issue #10 — enforcement is not one gate/directive
deepened in place; it is a **plugin set**, one independent plugin per
adopted methodology, modeled on how core ships `freelunch`/`scout`/
`warrant`/`terse` as separate plugins in
`tokenmaxxxer-core/.claude-plugin/marketplace.json` rather than one
monolithic `core` plugin. §0 below is the mandatory plugin inventory;
§1–§2 show how phase-1 and phase-2 norms are each a composition of
those plugins, not separate machinery.

- **Survey-basis pointer**: `docs/issue-10/reports/requirements-engineering/survey.md`
- **Scout brief**: `docs/issue-10/reports/requirements-engineering/scout-brief.md`
- **Adopted-norm source (unchanged, not re-derived here)**:
  `docs/issue-1/proposals/requirements-engineering.md`

## Problem / scope

Issue #10: the methodology this role adopted in the prior maturation
round (issue #1) exists only as documentation — a one-line `PRODUCES`
string in `directive.sh` and prose in `README.md`'s Doctrine section.
The approver's follow-up comment rejects deepening this into a single
gate/directive and requires instead that each adopted methodology become
its own self-contained plugin (directive/gate/agent/test as needed),
registered in this repo's `marketplace.json`, each owning exactly one
methodology — and that the phase-1 (기획서) and phase-2 (산출물) norms
themselves be expressed as *which plugins combine* to produce them, not
as prose describing a single enforcement pass. This proposal designs
(not implements) that plugin set at a level concrete enough that phase 2
can build directly from it.

## (0) Plugin inventory (mandatory)

Four new plugins, each living at `<plugin-name>/` alongside the existing
`requirements-engineering/` role plugin in this repo, each with its own
`.claude-plugin/plugin.json` and registered as its own entry in
`.claude-plugin/marketplace.json` (four new entries added to the existing
`plugins` array — the current single `requirements-engineering` entry
stays, unchanged, as the role plugin these compose with, exactly the
shape `tokenmaxxxer-core`'s marketplace.json already uses for
`core`+`freelunch`+`scout`+`warrant`+`terse`).

| Plugin | Methodology owned | Components (phase 2) | Source |
|---|---|---|---|
| `req-id-gate` | Facet A — structured requirements doc: unique `REQ-` ID + explicit verification condition per requirement | `hooks/req-id-gate.sh` (PreToolUse, `Write\|Edit\|MultiEdit`), `hooks/hooks.json`, `tests/req-id-gate-test.sh` | ISO/IEC/IEEE 29148 skeleton + Given/When/Then acceptance-criteria form, per `docs/issue-1/proposals/requirements-engineering.md` (b)(1)/(c) |
| `traceability-matrix-gate` | Facet B — traceability matrix: fixed columns (ID, Description, Source, Downstream Link), every facet-A ID present as a row | `hooks/traceability-matrix-gate.sh` (PreToolUse, same path scope), `hooks/hooks.json`, `tests/traceability-matrix-gate-test.sh` | RTM convergence across surveyed PM/testing tooling, per (b)(2)/(c) |
| `ambiguity-resolution-gate` | Facet C — ambiguity list, resolved: heading present, each entry resolved or explicitly escalated, explicit "none found" if empty | `hooks/ambiguity-resolution-gate.sh` (PreToolUse, same path scope), `hooks/hooks.json`, `tests/ambiguity-resolution-gate-test.sh` | RE literature's ambiguity-as-distinct-activity convention, per (b)(3)/(c) |
| `proposal-discipline-gate` | Phase-1 proposal norm: the 7 required sections (Problem/scope, Survey-basis pointer, Adopted norm, Rejected alternative, Plugin-reflection plan, Verification plan, Status) + citation/"assumption"-labeling discipline | `hooks/proposal-discipline-gate.sh` (PreToolUse, scoped to `docs/issue-*/proposals/*requirements-engineering*.md`), `hooks/hooks.json`, `tests/proposal-discipline-gate-test.sh` | `docs/issue-1/proposals/requirements-engineering.md` (a) |

Each plugin is self-completing and single-methodology: it may ship its
own `PreToolUse` gate, its own test file, and — only where the
methodology has a genuine repeated front-loading procedure (see the
`req-id-gate` note below) — its own `agents/` file. No plugin checks more
than the one methodology named in its row; this is the structural
difference from the rejected prior design, which put all three facets
plus the phase-1 section check into one `methodology-gate.sh`.

`req-id-gate` is the one plugin proposed to also carry an agent file,
`agents/requirements-scout.md` — "before drafting a record, name the
upstream hypothesis, elicit ambiguities, draft requirement IDs before
prose" — because it is the only facet whose ordering constraint
(elicitation → ID → verification condition, per (b)(1)) benefits from
front-loading rather than pure back-stop checking. The other three
plugins are gate-only; a repeated multi-session hunt cadence (core's
`warrant-hunter` shape) is not present for their methodologies, per the
scout brief's "pattern to skip."

## (1) Phase-1 (기획서) norm — as a plugin composition

The phase-1 proposal norm is **`proposal-discipline-gate` alone**,
composed with core's already-installed `scout` plugin (phase-1 research,
unchanged, out of this proposal's scope) and this role's own
`requirements-engineering` role plugin (branch/write-scope/contract
mechanics, unchanged). No facet gate (`req-id-gate`,
`traceability-matrix-gate`, `ambiguity-resolution-gate`) fires on a
proposal path — those are phase-2 content methodologies, not phase-1
process methodology. This is a deliberate 1-to-1: one plugin, one
process, matching the "one methodology = one plugin" instruction rather
than letting `proposal-discipline-gate` absorb any content-facet
checking.

**Check logic** (`proposal-discipline-gate.sh`, pseudocode — phase 2
fills in the exact regex, mirrors the fail-closed/path-scoped/kill-switch
shape of `pricing/hooks/methodology-gate.sh`):

```
scope: ^docs/issue-[0-9]+/proposals/.*requirements-engineering.*\.md$
resolve resulting text (Write=content; Edit/MultiEdit=reconstruct;
  deny if unreconstructable)
missing = []
for section in ["problem", "survey-basis", "adopted norm",
                 "rejected alternative", "plugin-reflection",
                 "verification plan", "status"]:
    if section-heading-or-equivalent not in text.lower(): missing.append(section)
if missing: deny("proposal missing required section(s): " + ", ".join(missing)
                  + " — per docs/issue-1/proposals/requirements-engineering.md (a)")
else: exit 0
```

## (2) Phase-2 (산출물) norm — as a plugin composition

The phase-2 deliverable-record norm is the **conjunction of all three
facet gates**: `req-id-gate` AND `traceability-matrix-gate` AND
`ambiguity-resolution-gate`, each independently registered in
`requirements-engineering/hooks/hooks.json`'s `PreToolUse` block
(three separate hook entries, same trigger pattern
`Write|Edit|MultiEdit`, same `RECORD_RE =
^docs/issue-[0-9]+/reports/requirements-engineering\.md$` path scope),
composed on top of (never instead of) core's role-agnostic
`record-fields-gate.sh` (contract §20 structural fields, untouched).
A write to the record path must pass all three facet gates plus canon's
existing structural gate to succeed — the record norm is what the three
plugins jointly enforce, not a fourth combined check.

### `req-id-gate` — check logic (pseudocode)

```
scope: RECORD_RE (above)
text = resolve resulting content (same reconstruction rule as above)
if not re.search(r'\bREQ-[0-9A-Za-z]+\b', text):
    deny("requirements-doc facet: no REQ-<id> found")
elif no REQ-<id> line is followed (within N lines) by a verification
     marker ("given", "when", "then", "verification:",
     "verification condition"):
    deny("requirements-doc facet: REQ-<id> present without a nearby "
         "verification condition")
else: exit 0
```

### `traceability-matrix-gate` — check logic (pseudocode)

```
scope: RECORD_RE
text = resolve resulting content
if not has_any("traceability matrix"):
    deny("traceability-matrix facet: no 'traceability matrix' section")
elif matrix section lacks all four column headers
     ("id", "description"/"desc", "source", "downstream"):
    deny("traceability-matrix facet: missing column(s)")
elif any REQ-xxx id present in the record text is absent from the
     matrix section text:
    deny("traceability-matrix facet: row missing for <id>")
else: exit 0
```

### `ambiguity-resolution-gate` — check logic (pseudocode)

```
scope: RECORD_RE
text = resolve resulting content
if not has_any("ambiguity"):
    deny("ambiguity facet: no 'ambiguity' section")
elif not (has_any("no ambiguities found", "none found", "no ambiguities")
          or has_any("resolution:", "escalated")):
    deny("ambiguity facet: no explicit 'none found' and no resolved/"
         "escalated entry")
else: exit 0
```

Each gate emits its own single-facet deny message (rather than the
prior design's one combined multi-facet deny) — this is the direct
consequence of "one plugin per methodology": a denied write is
attributable to exactly one plugin, and an approver/human reading a
PreToolUse denial knows which methodology it failed without needing to
parse a combined list.

### State tracking — is it needed?

Unchanged conclusion from the prior draft, re-derived per-plugin: no
plugin needs cross-file state. The one genuine ordering constraint
("elicitation → ID → verification condition") lives entirely within
`req-id-gate`'s own check (ID + nearby verification marker in the same
text), not across plugins or across files — `traceability-matrix-gate`
and `ambiguity-resolution-gate` each check their own facet independently
and do not need to know the others ran. Building a shared `loop_state`
file across the three plugins would introduce exactly the
cross-plugin coupling the "independent plugin" instruction rejects;
each plugin firing on the same `PreToolUse` event but resolving content
independently is sufficient, and matches how core's own
`freelunch`/`scout`/`warrant`/`terse` plugins fire independently without
polling each other's state.

## (3) Gate tests — per plugin

Each plugin ships its own test file (not one shared
`methodology-gate-test.sh`), following `implementation-rulebook/tests/
run-gate-tests.sh`'s `run()` helper (throwaway git repo per case,
synthetic JSON PreToolUse payload piped to the plugin's own gate script,
exit-code assertion):

| Plugin | Test file | Cases (allow + deny) |
|---|---|---|
| `req-id-gate` | `tests/req-id-gate-test.sh` | no-REQ-id (deny), REQ-id-no-verification (deny), REQ-id-with-verification (allow), foreign-path (allow), edit-unreconstructable (deny), kill-switch-off (allow) |
| `traceability-matrix-gate` | `tests/traceability-matrix-gate-test.sh` | no-matrix-section (deny), missing-column (deny), missing-row-for-id (deny), complete-matrix (allow), foreign-path (allow), kill-switch-off (allow) |
| `ambiguity-resolution-gate` | `tests/ambiguity-resolution-gate-test.sh` | no-ambiguity-section (deny), heading-only-no-resolution (deny), explicit-none-found (allow), resolved-entry-present (allow), foreign-path (allow), kill-switch-off (allow) |
| `proposal-discipline-gate` | `tests/proposal-discipline-gate-test.sh` | all-seven-sections (allow), missing-status (deny), missing-adopted-norm (deny), foreign-path (allow), kill-switch-off (allow) |

Each plugin's kill switch is its own env var
(`REQ_ID_GATE_OFF`, `TRACEABILITY_MATRIX_GATE_OFF`,
`AMBIGUITY_RESOLUTION_GATE_OFF`, `PROPOSAL_DISCIPLINE_GATE_OFF`) —
independently switchable, not one shared kill switch for all four, again
matching "independent plugin" rather than a shared enforcement toggle.
This repo's own `tests/run-gate-tests.sh` harness (phase 2 must create
it, nonexistent here today) runs all four plugins' test files, following
the harness shape of `implementation-rulebook/tests/run-gate-tests.sh`
by pattern only, not by vendoring.

## (4) Agents / checklists

Resolved per plugin, not left as a single open Option A/B choice:

- `req-id-gate` ships `agents/requirements-scout.md` (see §0's
  rationale) — the one methodology with a genuine front-loadable
  ordering constraint.
- `traceability-matrix-gate`, `ambiguity-resolution-gate`,
  `proposal-discipline-gate` ship no agent file — each is a pure
  back-stop check with no repeated multi-step procedure to front-load
  (a completeness check, not a hunt), matching the scout brief's
  "pattern to skip" reasoning for those facets specifically.

## Canon-reference discipline (unchanged)

None of the above requires copying core canon content:
- `requirements-engineering/hooks/directive.sh` continues to source
  `core/hooks/lib/role-directive.sh` by reference only (unchanged from
  the issue-2 conversion) and is unaffected — the four new plugins are
  additive siblings, not a modification of the role plugin.
- Each new plugin's gate script is new, role-owned logic — structurally
  patterned after `pricing/hooks/methodology-gate.sh` (a sibling
  rulebook, not core canon) but containing only its own one facet's
  content; none is a vendored copy of anything under `core/hooks/` or of
  `pricing/hooks/methodology-gate.sh` itself.
- Each new plugin's test file is new, role-owned test code, patterned
  after `implementation-rulebook/tests/run-gate-tests.sh`'s harness shape,
  not copied verbatim.
- Core's existing global gates (`record-fields-gate.sh` et al.) are
  untouched and continue to check only contract §20's role-agnostic
  fields; the four new plugins are additive on top of (never instead of)
  canon's structural check, same relationship pricing's gate already has.

## Verification plan

Phase 2 must, before landing:
1. Create the four plugin directories (`req-id-gate/`,
   `traceability-matrix-gate/`, `ambiguity-resolution-gate/`,
   `proposal-discipline-gate/`), each with `.claude-plugin/plugin.json`,
   `hooks/<name>.sh`, `hooks/hooks.json`, and `tests/<name>-test.sh`.
2. Add four new entries to `.claude-plugin/marketplace.json`'s `plugins`
   array (alongside the existing `requirements-engineering` entry),
   mirroring `tokenmaxxxer-core`'s marketplace.json shape.
3. Wire `req-id-gate`'s `agents/requirements-scout.md`.
4. Run each plugin's own test file and confirm every case in the §3
   table passes (all-allow and all-deny cases as specified).
5. Run core's own `stub-check.sh` (referenced, not vendored, per issue-5)
   against `requirements-engineering/hooks/` to confirm `directive.sh`
   remains in stub form and no gate-copy drift was introduced.
6. Record the pass/fail output of steps 4–5 in
   `docs/issue-10/reports/requirements-engineering.md` (phase-2 output,
   not written in this PR).

## Rejected alternatives

- **One combined `methodology-gate.sh` checking all three content facets
  plus the phase-1 section norm** — this proposal's own prior draft;
  rejected per the approver's explicit correction: it merges four
  distinct methodologies into one gate/directive, which is exactly the
  "단일 게이트/디렉티브 심화" the approver ruled out. Superseded by §0's
  four-plugin split.
- **Vendoring `pricing/hooks/methodology-gate.sh` verbatim and
  parameterizing it** — rejected: the file's method-taxonomy content
  (PSM/conjoint/CBC keyword lists) is pricing-domain-specific; the shape
  (fail-closed structure, path scoping, kill switch) is reused as a
  *pattern* per plugin, not as a *file*.
- **A single monolithic content check merged into canon's
  `record-fields-gate.sh`** — rejected per issue-2's own explicit finding:
  canon's gate is role-agnostic by design; folding role-specific facet
  checks into it would require every other role's canon-referencing
  rulebook to inherit requirements-engineering-specific regexes.
- **A shared cross-plugin `loop_state` file mirroring
  `coding-progress-gate.sh`** — rejected: no genuine cross-plugin
  ordering constraint exists (the one real ordering constraint is
  internal to `req-id-gate`'s own single-file check); a shared state file
  would couple otherwise-independent plugins, contrary to the "each
  plugin owns exactly one methodology" instruction.
- **One shared kill switch for all four plugins** — rejected for the same
  reason: independent plugins get independent toggles, matching core's
  own per-plugin (not per-marketplace) enablement model.

## Status

Proposal only. Awaiting Approve from an account listed in
`docs/specs/approvers.md` before phase 2 (creating the four plugin
directories, their `marketplace.json` entries, gate scripts, test files,
and `req-id-gate`'s agent file) begins.
