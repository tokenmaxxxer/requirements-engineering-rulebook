---
proposal: docs/issue-19/proposals/spec-alignment.md
---

# Hunt record — spec-alignment

## after-proposal — stance 0: assume the gate just touched is bypassable — find the bypass

Verdict: FINDING — proposed source/downstream_link resolution check (item 4) validates reference *shape* only, not existence, so any decoy path/sha/citation string satisfies it
Kind: design-error
Seed: docs/issue-19/proposals/spec-alignment.md (item 4, "source / downstream_link resolution")
cap_seconds: 60
tier: default
diff_stat_lines: ~3 files under docs/ (proposal + scout-brief + survey), proposal.md itself ~130 lines
started_at: 2026-08-09T00:00:00Z
ended_at: 2026-08-09T00:02:00Z

### Reproduce
The proposal's own text for item 4 states the planned check as:

  "a structural check ... that a non-'not yet linked' Source/Downstream
  Link cell value looks like a resolvable reference: a repo-relative
  path, a 7-40 char hex commit sha, or a bracketed/linked citation"

The verb ("looks like") and the description are shape-matching only
(regex against path syntax, hex-sha length/charset, bracket/link
syntax) -- nothing implies filesystem or git lookup. Given that stated
design, an author could satisfy the check with a cell value that has
correct syntax but points at nothing real, e.g. a made-up markdown
filename under docs/reports/ that was never created, or a 40-char
fabricated hex string that is not a real commit sha. Either matches the
stated shape rules and would pass, while resolving to nothing.

The proposal explicitly says it reuses an existing precedent for this
grammar: "matching the same reference shapes contract v3 s20 already
accepts for upstream-basis". Confirming that precedent is itself
shape-only, not existence-checking:

  grep -rn "reference shape\|resolvable reference\|upstream-basis" docs/issue-19/reports/implementation/survey.md docs/issue-19/reports/implementation/scout-brief.md

Both survey/scout-brief describe the existing rule in terms of matching
shapes, never in terms of an existence lookup (no mention of `test -f`,
`git cat-file`, or similar). So the proposal knowingly carries forward a
shape-only acceptance rule into a new enforcement surface (Source /
Downstream Link traceability cells) where the "How you'll know it
worked" smoke test claims it will deny "an unresolvable Source cell" --
which it will not, if the cell is well-formed but points at a
nonexistent target.

### Expected
Item 4's smoke test says: "a traceability-matrix row with an
unresolvable Source cell is denied by traceability-matrix-gate.sh."
Under the stated design, a syntactically well-shaped but nonexistent
path or fabricated sha is never flagged as unresolvable -- it is only
checked for syntax, not resolved. The phase-2 build should either (a)
add a real existence check (file/git lookup) for path- and sha-shaped
references, or (b) the proposal's acceptance text should be corrected
to say "syntax-validated, not existence-validated" so the stated smoke
test doesn't overclaim resolution enforcement the design doesn't
actually provide.

## before-landing — stance 0: assume the gate just touched is bypassable — find the bypass

Verdict: FINDING — req-id-gate.sh's EARS keyword grammar check (`_kw_order_ok` / `_ears_ok`) uses plain substring search (`text.upper().find(kw, pos)`) instead of word-boundary matching, so a `statement:` that merely contains a keyword as a substring of an unrelated word (e.g. "SHALL" inside "marshall", or "WHEN" inside "somewhen") satisfies `ears_pattern: ubiquitous`/`event-driven`/etc. without the statement actually being an EARS-grammar sentence.
Kind: silent-failure
Seed: req-id-gate/hooks/req-id-gate.sh lines 208-245 (`_kw_order_ok`, `_ears_ok`), added by the spec-alignment proposal items 2/3
cap_seconds: 180
tier: default
diff_stat_lines: >200 across >5 files (size:large)
started_at: 2026-08-09T00:00:00Z
ended_at: 2026-08-09T00:15:00Z

### Reproduce
Built a standalone harness (plugin/core copied from the cached core lib, plugin/req-id-gate/hooks/req-id-gate.sh copied from this repo) and fed a synthetic PreToolUse `Write` payload targeting a `requirements-engineering.md` record path (matching req-id-gate.sh's RECORD_RE) via stdin:

```
REQ-001
statement: The marshall handles the request when needed.
ears_pattern: ubiquitous
verification_method: Test
Given a request
When it arrives
Then it is handled
```

Run: `cat payload.json | bash req-id-gate.sh` (with CLAUDE_PROJECT_DIR pointed at the test repo root and CLAUDE_PLUGIN_ROOT_CORE at the core copy).

Control (same structure, statement without any "shall"-containing substring -- "The system handles the request when needed."):
```
implementation: refused -- ... whose statement text does not satisfy that pattern's EARS keyword-order grammar ... : REQ-001 (ears_pattern=ubiquitous).
EXIT: 2
```
This proves the gate does check for the literal word SHALL and denies when absent.

### Observed
With the crafted statement containing "marshall" (which contains "SHALL" as a substring), the gate exits 0 with no denial:
```
EXIT: 0
```
The record is accepted as fully spec-aligned even though the requirement's statement text contains no actual EARS "SHALL" keyword -- the check passed on the accidental substring inside "marshall".

### Expected
`_ears_ok`'s ubiquitous branch (and `_kw_order_ok`'s WHEN/WHILE/WHERE/IF search) should require the keyword as a whole word (e.g. regex `\bSHALL\b`), so that a statement without an actual EARS keyword is correctly flagged as `mismatched_ears` and denied, matching the behavior already exhibited by the control case.
