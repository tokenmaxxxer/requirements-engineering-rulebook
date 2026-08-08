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
