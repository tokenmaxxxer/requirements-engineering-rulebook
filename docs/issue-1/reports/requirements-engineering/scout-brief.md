# Scout brief — requirements-engineering methodologies & deliverable norms (issue #1)

4-angle sweep, no deepening round needed (findings converged and were
decision-relevant on the first pass; a second round would not change which
norms to adopt). Wall-clock ~2 min (`date -u` before/after: 12:08:19Z start).

## Category must-bes (what every credible source agrees a requirements
artifact needs)

1. **Structured, IDed, traceable requirements** — ISO/IEC/IEEE 29148 fixes
   a section skeleton (Introduction → Product/System Overview →
   Requirements [interfaces / functional / quality-of-service /
   compliance] → Verification → Appendixes) and requires each requirement
   be independently identifiable and verifiable.
2. **Traceability is a matrix with fixed core columns**, not prose: every
   source converges on Requirement ID, Requirement Description, and a link
   forward to a design/test artifact and status (Pass/Fail/Blocked/Not Run,
   Covered/Not Covered) as the minimum viable RTM shape.
3. **Every requirement/story needs an explicit "done" signal** — IEEE 29148
   calls this "verification"; the Agile lineage (INVEST, Given/When/Then
   acceptance criteria) calls it acceptance criteria. Both traditions agree
   a requirement without a checkable completion condition is not yet a
   requirement.
4. **Ambiguity is a first-class defect category to detect and log, not
   just avoid** — the RE literature treats ambiguity detection/resolution
   as its own phase (checklists, NLP-assisted detection, formal
   inspection), distinct from writing the spec itself.

## Performance axes strong sources compete on

- **Upfront-heavy (IEEE 29148 / BRD-PRD) vs. incremental (user
  stories/INVEST)**: formal SRS-style docs front-load a near-complete
  requirement set before build; Agile stories are atomic, negotiable, and
  written incrementally as the team learns. Trade-off is completeness/
  auditability vs. speed/adaptability.
- **Enterprise/compliance rigor (BRD, regulated-industry SRS) vs.
  product-velocity rigor (PRD, story-driven)**: BRD-style docs carry
  business case, KPIs, and compliance provenance; PRD/story-driven work
  optimizes for translating validated product decisions into buildable
  units fast.
- **Traceability depth**: minimal RTMs stop at requirement→test; mature
  ones add priority, risk level, and owner columns and treat the matrix as
  a living document requiring scheduled re-review, not a one-time
  artifact.

## Pattern to adopt / pattern to skip

- **Adopt**: IEEE/ISO 29148's discipline of a fixed section skeleton +
  unique requirement IDs + explicit verification condition per
  requirement, paired with INVEST/Given-When-Then-style acceptance
  criteria as the concrete "verification" instantiation — this matches
  this role's stated `decides` mandate (검증가능·일관·추적 가능) almost
  verbatim and is the only convergence point across both the standards
  tradition and the practitioner tradition.
- **Skip**: adopting a full heavyweight BRD/PRD/SRS *document-type
  taxonomy* (BRD vs PRD vs MRD vs Tech Spec as separate deliverables) —
  this role's `write_scope` is `[]` (report-only, single record artifact)
  and `hand-off` explicitly pushes screen/flow design to
  `interaction-design`; multiple parallel document types would exceed
  this role's scope and duplicate work the hand-off already routes
  elsewhere.

## GAP LINE

Survey (`docs/issue-1/reports/requirements-engineering/survey.md`) found
this repo already has: a role identity block naming three produces-labels
("structured requirements doc", "traceability matrix", "ambiguity list
resolved") and the generic contract v3 §20 record-fields gate (checked by
core canon, role-agnostic). It is missing: any internal structure for
those three labels (no ID scheme, no fixed RTM columns, no acceptance-
criteria form, no ambiguity-log/resolution protocol), any
requirements-engineering-specific phase-1 proposal template or citation
convention, and any gate that checks role-specific section presence
(canon's gate only checks structural fields every role shares, not this
role's content).

## Stage count / mode

4 search angles run concurrently in one batch (standard-body / traceability
practice / practitioner deliverable-type comparison / ambiguity-elicitation
research), zero deepening rounds — first-pass results already converged
across independent source families (standards body, QA/testing tooling
vendors, product-management blogs, RE academic literature) on the same
must-bes, so a second round was judged not decision-relevant. Budget used:
1 stage, well under the 3-minute cap.

## Assumptions (unsourced)

- That this role's single "record" artifact should embed all three
  produces-components (doc + matrix + ambiguity list) as sections of one
  record rather than three separate files, is an assumption drawn from
  `write_scope: []` (single report-only artifact), not from any scouted
  source — none of the sources address this repo's specific
  contract-v3/plugin record-file convention.

Sources:
- [ISO/IEC/IEEE 29148 Requirements Specification Templates](https://www.reqview.com/doc/iso-iec-ieee-29148-templates/)
- [ISO/IEC/IEEE 29148:2018 SRS Example Template](https://www.well-architected-guide.com/documents/iso-iec-ieee-29148-template/)
- [IEEE SA — ISO/IEC/IEEE 29148-2018](https://standards.ieee.org/standard/29148-2018.html)
- [Requirements Traceability Matrix (RTM): The Ultimate Guide](https://planyway.com/blog/requirements-traceability-matrix)
- [Requirements Traceability Matrix (RTM): Guide & Templates 2026](https://testomat.io/blog/the-ultimate-guide-to-rtm-requirements-traceability-matrix/)
- [What is a Requirements Traceability Matrix? + Free RTM Template](https://project-management.com/requirements-traceability-matrix-rtm/)
- [PRD vs MRD, BRD, Tech Spec, and User Stories](https://clickhelp.com/clickhelp-technical-writing-blog/prd-vs-mrd-brd-tech-spec-and-user-stories-whats-the-difference/)
- [BRD vs SRS vs PRD: Which Requirements Doc to Use](https://www.modernrequirements.com/blogs/brd-vs-srs-vs-prd-requirements/)
- [INVEST in good user stories](https://www.slideshare.net/slideshow/invest-in-good-user-stories-presentation/648546)
- [Requirement Elicitation: Techniques, Examples [Free Checklist]](https://www.projectpractical.com/requirement-elicitation-checklist/)
- [Detecting Ambiguities in Requirements Documents Using Inspections](https://cs.uwaterloo.ca/~dberry/FTP_SITE/reprints.journals.conferences/KamstiesBerryPaech2001DetectingAmbiguity.pdf)
