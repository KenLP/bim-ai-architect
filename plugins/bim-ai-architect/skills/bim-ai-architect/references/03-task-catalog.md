# 03 - Lookup: what common BIM tasks should be built with

Look the sub-task up here before scoring it yourself. "Mode" column: **D** deterministic · **A** adaptive · **H** hybrid · **Human**. The "Pattern" column points to `02-patterns.md`. The table is a starting point; if your context differs (volume, consequence, data), score it again with `01-rubric.md` and record why you departed from it.

## Reading and querying the model

| Task | Mode | How to split it | Pattern |
|---|---|---|---|
| Count, list, filter elements by category/level/parameter | D | The adapter's query/filter | n/a |
| Query in natural language | H | A → QuerySpec; D runs it; A phrases the answer | P1 |
| Arbitrary analytical questions over a large model | H | A writes query code; a read-only sandbox runs it | P10 |
| Quantity take-off (QTO) | D | Fixed formulas + units. A only helps map items | P5 for the mapping |
| Summarise a model ("what is in this model") | H | D aggregates the numbers; A writes the summary paragraph | P6 |
| Compare two versions of a model | D | Diff by stable ID; A summarises the notable changes | P6 |
| Find elements "like this one" | H | Embeddings/D features to shortlist candidates; A or Human chooses | P4 |

## Checking and verdicts

| Task | Mode | How to split it | Pattern |
|---|---|---|---|
| Check required parameters, data types, allowed values (IDS, EIR) | D | Rule engine / IDS checker | n/a |
| Author IDS / rules from EIR, BEP or regulation text | H | A drafts with citations; Human approves; tested with passing/failing cases | P3 |
| Code checks with numeric thresholds (exit width, height, area, distance) | D | Geometry kernel + rule pack. Note: the measurement is D, but *which threshold applies* often depends on declared inputs (occupancy, occupant load); if they are missing the result is `missing_data` | P3 |
| Establish the inputs a rule needs: room function, which doors are exits, which walls are fire walls | Human declares, D cross-checks | Taken from parameters a person filled in; D cross-checks against geometry/the room-door graph, and a mismatch gives `manual_review`. Do not let A guess: one wrong room function flips a whole series of verdicts | n/a |
| Qualitative clauses ("a sensible layout", "aesthetically acceptable") | Human | A gathers evidence and marks `manual_review`; no PASS/FAIL | P6 |
| Check naming conventions | D | Regex/grammar. A only suggests a corrected name | P5 |
| Check LOD/LOG, information completeness | D | Engine + LOD matrix as a parameter | n/a |
| Clash detection | D | Geometry | n/a |
| Group, prioritise and assign clashes | H | D computes features (systems, location, penetration depth) and scores priority with a points table for most cases; A only labels, from an enum, the *groups* the table does not cover; Human confirms, and approved cases are added to the table | P5 |
| Propose clash resolutions | H | A solver/A generates options; D checks geometry; Human chooses | P4 |
| Model health assessment (warnings, size, views, families) | D | Measured indicators; A writes the diagnosis and the order of work | P6 |
| Check clearances, escape routes, sight lines | D | Geometry/graphs | n/a |
| Reconcile the model with 2D drawings / documents | H | A (VLM) extracts from the drawings; D matches; Human resolves mismatches | First half of P2 |

## Generating and changing the model

| Task | Mode | How to split it | Pattern |
|---|---|---|---|
| Generate a model from a written brief | H | A → intent spec (no coordinates); D generates the geometric spec; D compiles; D reads back | P2 |
| The client's words → room programme / intent spec | H | A transcribes numbers with units and quotes, maps wishes to an enum, marks what is unsupported; D checks the quotes, converts units, asks back for missing slots; Human confirms | P1 + P9 |
| Budget feasibility check | D | Versioned unit-rate/factor tables. Without a table the result is `missing_data`; A does not estimate | n/a |
| Apply preference criteria (light, space, feng shui) | Human declares, D scores | Weights are configuration; A only picks a preset from a closed enum based on what the user said | P4 |
| Explain and compare the options | A | Read-only; every number traces back to the option data | P6 |
| CAD/PDF/photo → BIM | H | VLM/parser extracts → a spec with a schema; Human corrects the spec; D builds | P2 |
| Floor layout, massing options | H | A solver/generative method generates; D checks constraints; Human chooses | P4 |
| Bulk parameter fill when the correct value already has a source (a table made by a person, documents, a formula) | D | Rule + batch. One transaction | P8 |
| Parameter fill when the value must be inferred (classification, Uniclass/OmniClass codes) | H | Lookup table first; A for the remainder, closed enum + confidence; Human approves a sample | P5 + P8 |
| Filling life-safety parameters (fire rating, egress, structure) | Human decides, D writes | A person decides every value (usually per type). A may only suggest, and a suggestion reaches the model only through an approved lookup table. Record `origin` on filled values | P5 + P8 |
| Automatic fixes after a check | H | Policy by severity (automatic / approval / person only); writes go through the gate; re-check | P8 |
| Create views, sheets, schedules, tags | D | Recipe/template. A only interprets intent ("make the typical floor plan set") | P1 + P7 |
| MEP routing, clash avoidance | H | Routing algorithm; A chooses the strategy/parameters | P4 |
| Create a parametric family | H | A → parameter spec; D builds; read-back of dimensions | P2 |

## Documents, communication, process

| Task | Mode | How to split it | Pattern |
|---|---|---|---|
| Q&A over BEP, EIR, standards, contracts | A | RAG with mandatory citations; no source means "I don't know" | n/a |
| Write an inspection report | H | Numbers and statuses from D; A writes the words | P6 |
| Draft issues, RFIs, replies | H | A drafts; Human approves before sending | P6 + P8 |
| Classify and route issues/RFIs | H | A labels from an enum; D rules route them | P5 |
| Meeting minutes → action items | A | Structured output; Human confirms | n/a |
| Check file names, metadata, status codes per ISO 19650 | D | Grammar + code tables | n/a |
| Weekly project digest | H | D gathers events from the CDE; A writes | P6 |
| 4D schedule, 5D cost | D | Computation. A helps link model items to the WBS/BOQ | P5 |

## Interactive assistants

| Task | Mode | How to split it | Pattern |
|---|---|---|---|
| Assistant inside the authoring tool (chat → actions) | H | Agent picks tools/recipes; every write goes through the gate | P7 + P8 |
| Onboarding help for the software, command lookup | A | RAG over the documentation | n/a |
| Investigate an odd problem in the model | A (agent) | Read-only tools; conclusions come with element IDs for a person to check | P7 |

## Always D in a product

The only exception is experimenting in a sandbox on a copy, with logging (see `01-rubric.md` Q7).

- Unit conversion and rounding.
- Creating, looking up and joining **element IDs** (ElementId, UniqueId, IFC GlobalId). A never writes an ID itself.
- Arithmetic on quantities, areas, costs.
- PASS/FAIL of threshold checks.
- Executing changes to the model/CDE.
- Checking permissions, project scope, signatures, logs.

## Usually A, don't try to write rules

- Understanding natural requests, many languages, trade abbreviations.
- Reading regulation text to extract structure (at authoring time, with a person approving).
- Recognising meaning in carelessly chosen names, where the lookup table does not yet cover them.
- Writing words: explanations, summaries, correspondence.
- Reading scanned drawings and site photos (with verification).
