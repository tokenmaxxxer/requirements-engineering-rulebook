Subject: issue-19

# Scout brief

Mode: single targeted search (issue is a doc/hook alignment task against
an already-fixed external spec, not a product surface — one angle
sufficed to confirm the spec's own EARS grammar claim against the
canonical source; width=1, no fan-out needed for a verification lookup
of this size per scout's scale gate).

## Finding

EARS (Mavin et al., IEEE RE'09, Rolls-Royce) canonically defines five
requirement patterns (ubiquitous, event-driven, state-driven,
unwanted-behaviour, optional-feature) built from an ordered clause
grammar: `WHILE <precondition>, WHEN <trigger>, THE <system> SHALL
<response>`, each pattern using a subset of the clauses. The spec's sixth
value, `complex`, is documented by EARS practice as a chained
combination of the five base templates, not a seventh independent
grammar — matches the spec's own description ("Complex = chained
combination").

## Gap line

The rulebook's current req-id-gate already enforces a *richer* concept
(Given/When/Then + freeform verification condition) than the spec's flat
`ears_pattern` enum requires structurally, but enforces zero
*template-grammar* matching — no check ties a requirement's prose to its
declared pattern's clause shape. The spec's `reference_resolution` rule
explicitly wants that grammar match; this is a genuine gap, not a
renaming exercise.

## Adopt / skip

- Adopt: use the six spec enum values verbatim (they are the field's
  contract) and cite EARS's canonical grammar for the per-pattern
  template text in the proposal's adopted-norm section.
- Skip: implementing full natural-language grammar parsing (NLP-grade
  sentence structure checking) — out of proportion for a mechanical bash
  gate; a keyword/clause-order structural check (same rigor level as the
  existing REQ-id/verification-condition checks) is the fit, not a
  parser.

Sources:
- [Easy Approach to Requirements Syntax — Wikipedia](https://en.wikipedia.org/wiki/Easy_Approach_to_Requirements_Syntax)
- [EARS: Easy Approach to Requirements Syntax — Official guide, Alistair Mavin](https://alistairmavin.com/ears/)
