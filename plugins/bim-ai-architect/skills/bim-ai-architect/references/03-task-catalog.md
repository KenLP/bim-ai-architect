# 03 - Lookup: what common BIM tasks should be built with

Look the sub-task up here before scoring it yourself. "Mode" column: **D** deterministic · **A** adaptive · **H** hybrid · **Human**. The "Pattern" column points to `02-patterns.md`. The table is a starting point; if your context differs (volume, consequence, data), score it again with `01-rubric.md` and record why you departed from it.

## Reading and querying the model

| Task | Mode | How to split it | Pattern |
|---|---|---|---|
| Count, list, filter elements by category/level/parameter | D | The adapter's query/filter | n/a |
| Query in natural language | H | A → QuerySpec; D runs it; A phrases the answer | P1 |
| Arbitrary analytical questions over a large model | H | A writes query code; a read-only sandbox runs it | P10 |
| Quantity take-off (QTO) | D | Fixed formulas + units. A only helps map items | P5 for the mapping |
| Group quantities by cost code, apply unit rates | D | Name → cost code mapping table (P5 for unmatched names) and a versioned price book; A does not estimate prices | P5 |
| Cost items that are not modelled (formwork, temporary works) | D | Rule table made by people: driver quantity × factor, `origin: rule`; no rule → `missing_data`; the report shows derived items separately; each rule states what it excludes, to avoid counting an item already inside another rate | n/a |
| Highlight results in a 3D viewer | D | The ID list returned by the query, with a cap; A never lists elements itself | P1 |
| Summarise a model ("what is in this model") | H | D aggregates the numbers; A writes the summary paragraph | P6 |
| Compare two versions of a model | D | Diff by stable ID; A summarises the notable changes; two estimates or reports are compared the same way, by line key, with table changes shown as their own cause | P6 |
| Find elements "like this one" | H | Embeddings/D features to shortlist candidates; A or Human chooses | P4 |

## Checking and verdicts

| Task | Mode | How to split it | Pattern |
|---|---|---|---|
| Check required parameters, data types, allowed values (IDS, EIR) | D | Rule engine / IDS checker | n/a |
| Author IDS / rules from EIR, BEP or regulation text | H | A drafts with citations; Human approves; tested with passing/failing cases | P3 |
| Merge requirements from sources that disagree (specification, client feedback, revisions) | H | A extracts each source with quotes; D detects conflicts and superseded items; Human sets the order of precedence as configuration | P3 |
| Code checks with numeric thresholds (exit width, height, area, distance) | D | Geometry kernel + rule pack. Note: the measurement is D, but *which threshold applies* often depends on declared inputs (occupancy, occupant load); if they are missing the result is `missing_data` | P3 |
| Establish the inputs a rule needs: room function, which doors are exits, which walls are fire walls | Human declares, D cross-checks | Taken from parameters a person filled in; D cross-checks against geometry/the room-door graph, and a mismatch gives `manual_review`. Do not let A guess: one wrong room function flips a whole series of verdicts; a derived concept users ask about ("fire door", "wet room") gets a written definition in the versioned mapping table, approved by a person | n/a |
| Qualitative clauses ("a sensible layout", "aesthetically acceptable") | Human | D sets `manual_review`; A gathers and attaches evidence; Human decides; no PASS/FAIL | P6 |
| Check naming conventions | D | Regex/grammar. A only suggests a corrected name | P5 |
| Check LOD/LOG, information completeness | D | Engine + LOD matrix as a parameter | n/a |
| Clash detection | D | Geometry | n/a |
| Group, prioritise and assign clashes | H | D computes features (systems, location, penetration depth) and scores priority with a points table for most cases; A only labels, from an enum, the *groups* the table does not cover; Human confirms, and approved cases are added to the table | P5 |
| Propose clash resolutions | H | Solver generates options when the space can be solved or enumerated, otherwise A generates; D checks geometry; Human chooses | P4 |
| Model health assessment (warnings, size, views, families) | D | Measured indicators; A writes the diagnosis and the order of work | P6 |
| Check clearances, escape routes, sight lines | D | Geometry/graphs | n/a |
| Reconcile the model with 2D drawings / documents | H | D extracts from the drawings and issues IDs; A (VLM) labels what was extracted; D matches; Human resolves mismatches | First half of P2 |

## Generating and changing the model

| Task | Mode | How to split it | Pattern |
|---|---|---|---|
| Generate a model from a written brief | H | A → intent spec (no coordinates); D generates the geometric spec; D compiles; D reads back | P2 |
| The client's words → room programme / intent spec | H | A transcribes numbers with units and quotes, maps wishes to an enum, marks what is unsupported; D checks the quotes, converts units, asks back for missing slots; Human confirms | P1 + P9 |
| Budget feasibility check | D | Versioned unit-rate/factor tables. Without a table the result is `missing_data`; A does not estimate | n/a |
| Apply preference criteria (light, space, feng shui) | Human declares, D scores | Weights are configuration; A only picks a preset from a closed enum based on what the user said | P4 |
| Explain and compare the options | A | Read-only; every number traces back to the option data | P6 |
| Read vector drawings (DWG/DXF): entities, layers, blocks, text | D | Parser; keep the source handle as `src_id` | n/a |
| Read drawings as images (scanned PDF, photo) | H | D deskews, vectorises, groups repeated symbols into clusters, runs OCR and issues IDs; A (VLM) labels clusters and tokens from a closed enum; Human approves the labels | P5 |
| Classify layer/block names | H | Versioned class map first; A for unmatched names in one batched call; Human approves; approved rows join the map | P5 |
| Map a CAD block/symbol to an existing family + type | H | As the row "Match a source item to an existing library entry" | P5 |
| Rebuild geometry from 2D (pair wall lines, snap, host doors, close rooms) | D | Solver with tolerances; ambiguous spots are listed for a Human, never guessed | P2 |
| Values the result needs but the source lacks (heights, levels, scale, owners) | Human | Entered at setup with `origin: human`; defaults carry `origin: default`; A does not guess | n/a |
| Match a source item to an existing library entry (block → family/type, material name → material, spec item → product, room name → room type) | H | Lookup table first; A proposes only from the list of entries that actually exist, issued by D as a closed enum, with confidence and evidence; Human approves; approved rows join the table; no candidate → `missing_data`; adding a new library entry is a person's job, outside this flow | P5 |
| Floor layout, massing options | H | Solver or generative method generates (D when the space can be solved or enumerated); D checks constraints; Human chooses | P4 |
| Bulk parameter fill when the correct value already has a source (a table made by a person, documents, a formula) | D | Rule + batch. One transaction | P8 |
| Parameter fill when the value must be inferred (classification, Uniclass/OmniClass codes) | H | Lookup table first; A for the remainder, closed enum + confidence; Human approves per group of identical cases, with every instance listed | P5 + P8 |
| Filling life-safety parameters (fire rating, egress, structure) | Human decides, D writes | Each value is decided by a person (usually per type). A may only suggest, and a suggestion reaches the model only through an approved lookup table. Record `origin` on filled values | P5 + P8 |
| Automatic fixes after a check | H | Policy by severity (automatic only for cases identical to ones a person approved / approval / person only); writes go through the gate; re-check | P8 |
| Create views, sheets, schedules, tags | D | Recipe/template. A only interprets intent ("make the typical floor plan set") | P1 + P7 |
| MEP routing, clash avoidance | H | Routing algorithm; A only picks a strategy preset from a closed enum; parameters are configuration | P4 |
| Create a parametric family | H | A → parameter spec; D builds; read-back of dimensions | P2 |

## Documents, communication, process

| Task | Mode | How to split it | Pattern |
|---|---|---|---|
| Q&A over BEP, EIR, standards, contracts | A | RAG with mandatory citations; no source means "I don't know" | n/a |
| Write an inspection report | H | Numbers and statuses from D; A writes the words; with a fixed template D renders the whole report and A is not needed | P6 |
| Draft issues, RFIs, replies | H | A drafts; Human approves before sending. A message may go under a send policy a person approved; creating the issue or RFI record itself goes through the write gate | P6 + P8 |
| Classify and route issues/RFIs | H | A labels from an enum; D rules route them | P5 |
| Group duplicate issues/RFIs | H | D matches on element IDs and location first; A proposes groups by content; Human confirms merges, per group of identical cases when there are many | P5 |
| Assign an owner and a due date | D | Routing table (discipline × system × zone) and a due-date table by severity, both made by people; A only labels cases the tables do not cover | P5 |
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
| Record site progress by voice or photo | H | A turns speech into an intent; D resolves it against real IDs and asks back when ambiguous; writes go through the gate, `origin: human` plus `actor` for the speaker | P1 + P8 |

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
- Labelling what D extracted from scanned drawings and site photos (D measures, A names).
