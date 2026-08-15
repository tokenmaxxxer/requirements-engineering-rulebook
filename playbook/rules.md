---
name: requirements-engineering-playbook
subject: issue-1174
rule_count_floor: 23
axes: 7
tier: rich
---

# Requirements-engineering operational playbook

Condition -> choice -> source decision rules for drafting requirements
(contract v3 role: requirements-engineering). Distilled per-role
research per issue #1174 amendment 1; evidence trail in
docs/issue-1174/reports/scout-brief.md. Rules are decisions, not
definitions: each names the triggering condition and the choice it
forces.

## Axis 1 — EARS-pattern selection

1. Condition: the requirement holds under all system states with no
   trigger ("the system shall always X"). Choice: write it as a
   **ubiquitous** requirement — no When/While/Where clause, bare
   "The <system> shall <response>." Source: Mavin et al., EARS Guide
   (https://alistairmavin.com/ears/).
2. Condition: the requirement's behavior is triggered by a discrete
   event that can be detected at a point in time. Choice: use the
   **event-driven** template, "When <trigger>, the <system> shall
   <response>." Source: EARS Guide; Terzakis ICCGI 2013 tutorial.
3. Condition: the requirement's behavior is active only while a
   condition/state persists (not a point event). Choice: use the
   **state-driven** template, "While <state>, the <system> shall
   <response>." Source: EARS Guide.
4. Condition: the requirement describes handling of an error, fault,
   or undesired condition. Choice: use the **unwanted-behavior**
   template, "If <trigger>, then the <system> shall <response>," and
   route it to the failure-mode/exception-handling section, not mixed
   into the happy-path requirement. Source: EARS Guide.
5. Condition: the requirement applies only when an optional
   feature/configuration is present. Choice: use the **feature**
   (Where) template, "Where <feature is included>, the <system> shall
   <response>." Source: EARS Guide.
6. Condition: a drafted sentence needs two or more of When/While/Where
   clauses to be true. Choice: this is a **complex** EARS requirement
   — keep the clause order fixed (While-When-If-Where-shall-response,
   per EARS's own ordering) rather than inventing new sentence shape;
   if the clause count exceeds 2, split per Axis 4 instead. Source:
   EARS Guide (fixed clause ordering, "closely match common usage of
   English").

## Axis 2 — Verification-method selection

7. Condition: correctness can be confirmed by visual/documentary
   examination (e.g. a UI label matches spec text, a config value is
   present). Choice: verification method = **Inspection**. Source:
   ISO/IEC/IEEE 29148, four-method verification framework
   (https://www.cwnp.com/req-eng/).
8. Condition: correctness requires exercising the system and observing
   behavior end-to-end, without instrumented measurement (e.g. "the
   wizard completes in 3 clicks"). Choice: verification method =
   **Demonstration**. Source: ISO/IEC/IEEE 29148.
9. Condition: correctness requires a measured, repeatable execution
   against expected output (e.g. a numeric threshold, an API
   contract). Choice: verification method = **Test**. Source:
   ISO/IEC/IEEE 29148.
10. Condition: correctness cannot be directly observed or executed
    (e.g. a capacity/scalability projection, a security property
    provable only by modeling). Choice: verification method =
    **Analysis**. Source: ISO/IEC/IEEE 29148.
11. Condition: a requirement's verification method cannot be assigned
    to any of the four. Choice: treat this as a drafting defect, not
    an escape hatch — rewrite the requirement until one method
    applies; never leave verification_method unset. Source:
    ISO/IEC/IEEE 29148 (all requirements "verified through inspection,
    test, demonstration, or analysis").
11a. Condition: a requirement's verification_method is Test or
    Demonstration and the requirement's own acceptance condition can be
    expressed as a runnable check (a command, script, or query).
    Choice: pair the verification condition with that literal runnable
    check, not a prose description of what someone would run — a
    verification_method that stays prose-only when a concrete command
    exists is under-specified. Source: distilled from a widely-adopted
    Claude Code spec-authoring plugin's convention of attaching "a
    runnable verify command on every build step" to each acceptance
    criterion (evidence trail: this role's tool-landscape fold-in,
    docs/issue-1199/reports/requirements-engineering.md).
11b. Condition: a batch of requirements has just been drafted or
    revised and is about to hand off to a downstream role (plan,
    design, or implementation). Choice: run one explicit
    cross-requirement consistency/coverage pass over the whole batch
    before handoff — check for gaps and contradictions across the set,
    not only within each requirement individually — and log the pass
    itself in the traceability matrix's status field; do not treat
    per-requirement drafting quality as a substitute for a whole-batch
    check. Source: distilled from a widely-adopted Claude Code
    spec-driven-development plugin's dedicated cross-artifact
    consistency/coverage-analysis step run after task generation but
    before implementation (evidence trail: this role's tool-landscape
    fold-in, docs/issue-1199/reports/requirements-engineering.md).

## Axis 3 — Ambiguity detection & resolution

12. Condition: a requirement uses a listed weak word/phrase (adequate,
    as appropriate, as a minimum, effective, as required, normal,
    provide for, timely, easy to, user-friendly). Choice: replace with
    a measurable threshold or enumerated condition before the
    requirement is accepted; a weak word is a resolution-blocking
    defect, not a style nit. Source: NALABS bad-smell catalog
    (https://arxiv.org/pdf/2202.05641); ISO/IEC/IEEE 29148 NLP-quality
    framework.
13. Condition: a requirement uses a superlative, comparative phrase,
    or open-ended term ("best", "faster", "as needed", "etc."). Choice:
    flag as an ambiguity-smell and require a bounded restatement (a
    concrete comparator or an exhaustive list) before it can carry a
    requirement ID. Source: ISO/IEC/IEEE 29148 vagueness-avoidance
    guidance (per ambiguity/weak-word research summary,
    https://www.researchgate.net/publication/221552258).
14. Condition: a requirement statement admits two or more distinct
    readings under a plain reading by a domain-competent reader.
    Choice: log it in the ambiguity list (statement + candidate
    readings + resolution) per this role's `produces` field, resolve
    to one reading with the requesting stakeholder, and only then
    assign a requirement ID — an unresolved reading never gets an ID.
    Source: role produces-spec (README.md Doctrine); Ambiguity in NL
    Software Requirements case study.
15. Condition: a requirement is phrased as a negative statement ("the
    system shall not fail to..."). Choice: rewrite as the positive
    capability it actually asserts; a negative-of-a-negative is a
    documented ISO 29148 ambiguity trigger. Source: ISO/IEC/IEEE 29148
    vagueness-avoidance list (negative statements named explicitly).

## Axis 4 — Singularity / atomicity

16. Condition: a requirement sentence contains a conjunction ("and",
    "or") joining two independently verifiable capabilities. Choice:
    split into two requirements, each with its own ID, unless the
    conjunction is inside a single EARS response clause describing one
    atomic action. Source: INCOSE Guide for Writing Requirements, rule
    against conjunctions
    (https://visuresolutions.com/alm-guide/incose-guide-to-writing-requirements/).
17. Condition: a requirement's downstream verification would need two
    different verification methods (e.g. part Inspection, part Test)
    to close. Choice: this is a signal the requirement is not singular
    — split along the method boundary. Source: ISO/IEC/IEEE 29148
    singularity characteristic + verification-method framework
    (derived pairing).

## Axis 5 — Traceability-link granularity

18. Condition: the project is regulated/audit-bound or a requirement's
    failure has high blast radius (safety, compliance, payment).
    Choice: link at requirement-to-single-test granularity (1:1 or
    finer) in the traceability matrix. Source: EPLC Requirements
    Traceability Practices Guide, granularity matched to risk
    (https://www.hhs.gov/.../eplc_requirements_traceability_practices_guide.pdf).
19. Condition: the project is low-risk/exploratory and a fine-grained
    matrix would cost more reviewer time than it returns. Choice: link
    at feature-to-requirement-group granularity, coarser than 1:1, and
    say so in the matrix's status field rather than silently thinning
    detail. Source: EPLC guide ("shouldn't create unnecessarily
    detailed matrices for simple projects"); this role's
    `write_scope: []` boundary (documented judgment, not code).
20. Condition: a requirement changes after its matrix row already
    exists. Choice: update the row's downstream_link and status in the
    same change, never leave a stale link — a stale trace link is
    worse than a coarse one because it actively misleads. Source: EPLC
    guide, traceability as a living artifact.

## Axis 6 — Prioritization (scope-cut tie-break)

21. Condition: two requirements compete for a fixed delivery slot and
    both pass the Must/Should/Could MoSCoW screen at the same tier.
    Choice: break the tie by Kano category — a Must-Be (basic
    expectation) outranks a Performance requirement, which outranks a
    Delighter, within the same MoSCoW tier. Source: MoSCoW+Kano
    combined-use guidance
    (https://plane.so/blog/feature-prioritization-frameworks-rice-moscow-and-kano-explained;
    https://productschool.com/blog/product-fundamentals/kano-model).
22. Condition: a requirement cannot be classified into any MoSCoW
    tier because no stakeholder has stated its necessity. Choice: this
    is not a Could-Have by default — return it to elicitation before
    it enters the spec; MoSCoW tiering presumes the necessity question
    was already answered. Source: MoSCoW framework definition (Must =
    "critical to the product's viability").

## Axis 7 — REMOVAL: requirement subtraction and pruning

23. Condition: a requirement's capability is not traceable to any
    stated stakeholder need (Axis 6's "Necessary" characteristic
    fails) — this is **gold-plating**. Choice: delete the requirement
    outright rather than deprioritize it; a Won't-Have MoSCoW label is
    the wrong home for a requirement that should never have existed.
    Source: gold-plating vs scope-creep distinction
    (https://pmstudycircle.com/scope-creep-vs-gold-plating/); ISO/IEC/
    IEEE 29148 "Necessary" characteristic.
24. Condition: two or more requirements in the spec assert the same
    verifiable behavior under different IDs (redundant coverage).
    Choice: merge into one requirement and retarget every existing
    downstream_link to the surviving ID; never leave both live. Source:
    ISO/IEC/IEEE 29148 completeness/correctness characteristics
    (redundancy is a stated defect category).
25. Condition: a requirement is superseded by a later, more specific
    requirement covering the same behavior. Choice: remove the
    superseded requirement from the active spec (move to a superseded/
    archive record with the replacing ID cited), not left standing
    alongside its replacement — two active requirements for one
    behavior is an ambiguity source per Axis 3. Source: derived from
    ISO/IEC/IEEE 29148 correctness + singularity characteristics.
26. Condition: reviewing a draft spec, the reviewer's default search
    for changes is additive ("what's missing") and no explicit
    subtraction pass has been run. Choice: run a dedicated removal
    pass as a required spec-review step — ask "what can be deleted
    here" as its own question, not folded into the addition review —
    because reviewers structurally default to additive search and
    under-search subtractive options, especially under review-time
    pressure. Source: Adams, Converse, Hales & Klotz, "People
    systematically overlook subtractive changes," Nature 592 (2021)
    (https://www.nature.com/articles/s41586-021-03380-y).
27. Condition: a requirement has failed the ambiguity-resolution gate
    (Axis 3, rule 14) more than once across review cycles with no
    stakeholder able to resolve the reading. Choice: do not keep
    re-drafting it indefinitely — recommend removal from this spec
    version and log it as `unverifiable`/`source-unresolvable`
    (this role's loop_state vocabulary) rather than shipping a
    requirement nobody can verify. Source: role's own loop_state
    vocabulary (README.md); Nature 2021 subtraction-neglect (removal
    must be a stated option, not just re-elaboration).

## Removal-category self-check

A playbook is bar-not-met if every rule is additive (issue #1174
amendment 4). Rules 23-27 above are the removal category: gold-plating
deletion, redundancy merge, supersession removal, mandatory subtraction
review pass, and unresolvable-requirement removal. 5 of 27 rules are
removal rules — non-zero, satisfying the depth-gate's removal-category
requirement.
