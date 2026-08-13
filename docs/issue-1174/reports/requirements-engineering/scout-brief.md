---
name: scout-brief
subject: issue-1174
role: requirements-engineering
---

## Research protocol used (per issue #1174 amendment 1, operator 2026-08-13)

Three-layer web-fetched research, no pretrained-recall content. Mode:
batched-sequential WebSearch calls in two rounds (parallel tool calls
within each round), one session, roughly 8 minutes wall-clock. Queries
run and sources actually read are listed per rule below and in
`Sources:`.

Round 1 queries: EARS pattern syntax; INCOSE Guide for Writing
Requirements characteristics/rules; ISO/IEC/IEEE 29148 verification
methods; requirements ambiguity/smells/weak-words research; Adams et
al. Nature 2021 subtraction-neglect; gold-plating/scope-creep removal
practice.
Round 2 queries: requirements-traceability-matrix granularity best
practice; MoSCoW/Kano prioritization decision rules.

## Decision axes (this role's domain, at operator-example granularity)

1. **EARS-pattern selection** — which of the 5 sentence templates fits
   a given requirement's triggering condition.
2. **Verification-method selection** — inspection vs analysis vs
   demonstration vs test, per requirement's testability class.
3. **Ambiguity detection & resolution** — which language patterns flag
   a requirement as unverifiable, and how to resolve each.
4. **Singularity / atomicity** — when and how to split a compound
   requirement.
5. **Traceability-link granularity** — how fine a downstream/source
   link should be, tied to change-impact and audit need.
6. **Prioritization** — MoSCoW/Kano tie-break rule for ordering
   requirements when scope must be cut.
7. **REMOVAL — requirement subtraction/pruning** — when to delete,
   merge, or decline a requirement (gold-plating, scope creep,
   redundant/superseded, unverifiable-and-unfixable).

Tier (per docs/issue-1174/proposals/operational-playbook-program.md
(b)): rich. N_min = max(12, axes(7) x 3) = 21. Delivered: 24 rules in
playbook/rules.md, rule_count_floor: 21.

## Must-bes extracted from the field (Kano-must, this domain)

- Every requirement statement maps to exactly one of the 5 EARS
  templates or is flagged non-conforming (Mavin et al.; INCOSE V4).
- Every requirement carries one of the 4 ISO/IEC/IEEE 29148
  verification methods, not left unverifiable by default.
- Ambiguity is checked against a named weak-word list, not vibes.
- Subtraction is a first-class review step, not an afterthought
  (structural counter to the Adams et al. 2021 finding that people
  default to additive-only search).

## Performance axes the field competes on

- Precision of ambiguity taxonomy (smell-catalog depth: NALABS/deep
  smell-detector research vs bare "avoid vague words" advice).
- How mechanically the verification-method choice is derivable from
  requirement shape (29148's four-method split is close to mechanical;
  weaker guides leave it to reviewer judgment).

## Adopt / skip

- Adopt: EARS as the default sentence-template gate (mechanical,
  well-sourced, matches this repo's own req-id-gate intent).
- Adopt: ISO 29148's 9-characteristic list as the correctness rubric,
  already partially embedded in this rulebook's Doctrine section.
- Skip: full INCOSE 42-rule catalog verbatim — too fine-grained for a
  playbook; distilled into the axis rules below instead, citing the
  guide as source rather than reproducing all 42.

## Gap line

Already met by this rulebook's existing Doctrine (README.md, EARS
pattern + traceability/ambiguity gate plugins): the four gate-shape
mechanics (req-id, traceability-matrix, ambiguity-resolution,
proposal-discipline). Missing before this playbook: condition-choice-
source decision rules a session can apply while drafting, not just a
shape check after the fact — including the removal category, which
had zero coverage anywhere in this repo.

Sources:
- https://alistairmavin.com/ears/
- https://www.iaria.org/conferences2013/filesICCGI13/ICCGI_2013_Tutorial_Terzakis.pdf
- https://visuresolutions.com/alm-guide/incose-guide-to-writing-requirements/
- https://www.incose.org/docs/default-source/working-groups/requirements-wg/guidetowritingrequirements/incose_rwg_gtwr_v4_summary_sheet.pdf
- https://www.cwnp.com/req-eng/
- https://www.researchgate.net/publication/385802396_Well-Formed_Quality_of_System_Requirements_for_Verifying_to_ISO_29148-2018_A_Natural_Language_Processing_NLP_Based_Framework_and_Quantitative_Metric
- https://arxiv.org/pdf/2404.11106
- https://www.researchgate.net/publication/221552258_Ambiguity_in_Natural_Language_Software_Requirements_A_Case_Study
- https://www.nature.com/articles/s41586-021-03380-y
- https://medium.com/rose-digital/the-two-silent-killers-of-projects-scope-creep-and-gold-plating-and-how-to-stop-them-ed49c702098c
- https://pmstudycircle.com/scope-creep-vs-gold-plating/
- https://www.hhs.gov/sites/default/files/ocio/eplc/EPLC%20Archive%20Documents/24%20-%20Requirements%20Traceability%20Matrix/eplc_requirements_traceability_practices_guide.pdf
- https://plane.so/blog/feature-prioritization-frameworks-rice-moscow-and-kano-explained
- https://productschool.com/blog/product-fundamentals/kano-model
