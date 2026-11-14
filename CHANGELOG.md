# Changelog

## 0.2.0 (2026-11)

Generalised after running the skill on drawings-to-BIM, materials checking, IFC Q&A, CDE issue handling and cost estimating.

- Image sources: "A labels, D measures". D extracts lines, symbols and text and issues IDs; the LLM only labels them. Evidence is the image region.
- LLM calls per signature (distinct name, symbol cluster), not per element.
- New general catalog row: match a source item to an existing library entry (block to family, material name to material, spec item to product). The single "CAD/PDF/photo to BIM" row is split into six.
- Sources that disagree (specification, client feedback, revisions): code detects conflicts, a person sets precedence.
- Two new context items in Step 1: what the source lacks, and what to do when input is ambiguous.
- Three shapes of write in the brief template: change an existing model, build a new file from a locked spec, only send results. Sending to internal teams counts.
- Writes to non-model systems: de-duplication key and a stale-state check before writing.
- New BIM traps: where materials live; 2D drawings lack heights and scale; GlobalId drift across consultants.
- Catalog rows for cost codes and unit rates, unmodelled cost items, duplicate issues, owner and due date, viewer highlighting, site progress by voice or photo.
- Clarified: Step 1 lists ten context items (ask at most five); how to count hybrid rows; "design time" means before a rule takes effect.
- Write gate: the LLM proposes values or an intent and code builds the ChangeSet; creating elements in a live model is a ChangeSet; targets with no transaction; offline approvals; large batches approved per group; ownership and connected elements.
- Sending versus writing: a message or report is a send; creating an issue or RFI record is a write.
- Removed contradictions found by repeated test runs and two read-only audits (who generates options, who chooses, which status set applies, values of `origin`, when a policy may act automatically).

## 0.1.0 (2026-11)

First public release.

- Three modes: design (Architecture Brief), review (anti-pattern checklist), ask (short answer).
- Rubric: six stages, seven questions.
- Ten combination patterns.
- Task catalog of about 45 common BIM tasks.
- Contracts, write gate, BIM-specific traps, rules for adding an LLM layer to a deterministic core.
- Evaluation and cost guidance.
- 53 coded anti-patterns and five path traces for reviews.
- Field notes with sources.
