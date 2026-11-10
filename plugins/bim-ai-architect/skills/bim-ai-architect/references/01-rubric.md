# 01 - Rubric: should this be deterministic, adaptive, or hybrid?

The unit of decision is NOT "the whole app" but **each sub-task**. A good BIM AI app is almost always hybrid: a few adaptive sub-tasks at the edges, a deterministic core. The right question is "where does the boundary sit?"

## Vocabulary

| Symbol | Meaning | Includes | Properties |
|---|---|---|---|
| **D** | Deterministic | Rule engine, geometry kernel, query/filter, compiler, validator, solver, lookup table, regex | Same input → same output. Unit-testable. Every step can be explained. Cheap to run repeatedly |
| **A** | Adaptive | LLM, VLM, agent loop, embedding/RAG | Tolerates ambiguous input and the long tail. Output varies and must be checked. Costs scale with tokens |
| **H** | Hybrid | A at the edges + D at the core, joined by a contract | See `02-patterns.md` |
| **Human** | A person | Approves, labels, makes accountable decisions | Slow and expensive, but the only place that carries legal responsibility |

## The six stages of a BIM AI app and the default mode

Break the app along this chain first, then score each sub-task.

| Stage | Question it answers | Default | Common exception |
|---|---|---|---|
| 1. **Read** | What does the model/CDE/document set contain? | D (adapter, query) | Unstructured source (PDF, scanned drawing, photo) → A extracts against a schema |
| 2. **Interpret** | What does the user / the text mean? | A | Commands with a fixed syntax already (form, CLI, preset) → D |
| 3. **Judge** | Compliant or not? How much? Where? | D | Purely qualitative criteria ("a sensible layout") → A scores + Human approves, and it is not called "compliance" |
| 4. **Decide** | What to do with the result? Which item to fix, in what order? | H (D policy table, A proposes) | Few options, all enumerated → D |
| 5. **Write** | Change the model/CDE | D + approval gate | No exceptions |
| 6. **Present** | Explain, report, draft correspondence | A writes the words over D's numbers | Fixed report template → D renders the template |

Work done once before anything runs (authoring rules from text, building a lookup table) does not belong to the six stages above; record its stage as **Design-time** and score it like any other sub-task.

## Seven questions

Ask them in order. **Q1-Q3 are gates:** a "yes" means the writing, computing and judging parts of that sub-task are D, with no further debate. **Q4-Q5 decide the rest** (where values, intent and options come from). **Q6-Q7 are adjustments** and always apply. A sub-task is usually justified by two or three questions (for example "Q1 for the write path, Q5 for how the value is produced").

**Q1. Does this sub-task WRITE to the model, the CDE or a live system, or send results outside the team?**
Yes → the write path is **D + gate** (validate → preview, dry run by default → approve → one transaction → read-back → log). A may only *propose the payload*; it never holds the pen. For sending results outside (email, issue, a report for a third party), the minimum gate is an approver and a log. Details: `04-contracts-guardrails.md`.

**Q2. Is there one correct answer that can be computed from the data?**
Counting, measuring, summing quantities, comparing to a threshold, converting units, table lookups, checking name syntax → **D**. LLMs are unstable at arithmetic and geometry; a wrong number that looks plausible is the most expensive kind of error in BIM.

**Q3. Is the result a verdict that must be repeatable and explainable?**
Code compliance, acceptance checks, LOD, clashes, fire safety → **D judges**. A may: find the relevant rule, explain why something failed, suggest a fix. A may not: change PASS/FAIL, change a number.
The test: run it twice on the same model; may the two results differ? No → D.

**Q4. Is the input ambiguous or unstructured?**
Natural-language questions, regulation clauses, design briefs, carelessly named families, notes in text parameters → **A to turn it into structure** (JSON against a schema, closed enums). Then return to Q2 and Q3 for what remains. A stops where structure begins.

**Q5. Can the output be verified by a machine, cheaply?**
- Verifiable (run it, validate the schema, read the model back, test) → **A + verifier** is safe (the propose → check → choose pattern). Condition: the verifier checks *content*, not just form. "Value is not empty" or "correct format" is not verification; in that case treat the output as unverifiable.
- Unverifiable, high consequence → **Human approves**, A only drafts.
- Unverifiable, low consequence → **A**, labelled "AI suggestion".

**Who generates the options?** When the job is proposing solutions (floor layouts, pipe routes, clash resolutions), also ask: can the solution space be *enumerated* or *solved with a solver*? Yes → D generates and scores; A only interprets the input requirements and explains the result. No (too large, or the criteria cannot be formalised) → A generates many options, D filters them with a validator, and a high rejection rate is accepted.
Preference weights (light versus space, feng shui criteria) belong to a person or to configuration. A may *pick a preset* from a closed enum based on what the user said; A never sets weights itself.

**Q6. How many elements does this run over?**
Thousands of elements or more → **A writes once, D runs N times**. A produces the filter/query/mapping table; the engine applies it. No LLM call per element, no dumping the whole model into context.

**Q7. Has this sub-task stabilised?**
- An A decision that keeps coming out the same way → **lower it to D** (lookup table, rule, keyed cache). This is the *ratchet*: each week the A part shrinks and the D part grows.
- A D rule set swelling with exceptions (names, spellings, languages) → **add an A layer for the long tail**, keep D for the body.
- Not yet sure what this sub-task really is (still prototyping) → let A do all of it in a sandbox to learn, log every decision, then reapply the rubric once there are 20-50 real cases.

## Two-axis matrix (quick view)

```
                       CONSEQUENCE OF BEING WRONG / NEED TO EXPLAIN
                       low                        high
                 ┌──────────────────────┬─────────────────────────────┐
  INPUT     high │ A free               │ H: A interprets → schema →  │
  AMBIGUITY      │ (suggestions, digest,│ D executes + verifier +     │
                 │  search, drafts)     │ Human approves write/verdict│
                 ├──────────────────────┼─────────────────────────────┤
            low  │ D (or A for now while│ Pure D. Keep A away from    │
                 │  prototyping, then   │ the compute path and the    │
                 │  lower it)           │ write path                  │
                 └──────────────────────┴─────────────────────────────┘
```

## Quick recognition signals

| You hear in the request | Leans towards | Because |
|---|---|---|
| "how many", "total", "area", "distance", "≥", "≤" | D | There is a correct answer |
| "per QCVN (Vietnam's national building code) / IBC / ISO 19650 / EIR" | D judges, A authors the rules offline | The verdict must be repeatable |
| "users type in their own language, freely" | A at the Interpret stage | Ambiguous input |
| "every project names families differently" | A classifies + cache → D | Long tail |
| "fix the model automatically" | D + gate, A proposes | Write path |
| "from PDF/DWG drawings or photos" | A (VLM) extracts → schema → D builds | Unstructured |
| "propose options", "optimise" | D generates if the space can be enumerated or solved; otherwise A generates → D checks → Human chooses | Search space, verifiable |
| "explain", "summarise", "draft an RFI" | A, numbers injected from D | Language |
| "100,000 elements", "runs nightly" | D runs, A only in configuration | Volume, cost |
| "the client will sign off the result" | D + Human | Accountability |

## The architecture ladder: pick the lowest rung that works

Only after splitting D/A do you choose the shape of the A part:

1. **One LLM call** with structured output: enough for most Interpret and Present work.
2. **A fixed workflow** (chain, routing, parallel): when the steps are known in advance. Easy to test, easy to measure.
3. **An agent** (a loop that picks its own tools): only when the number and order of steps are unknown in advance, and there is a checkable stop signal.
4. **Multi-agent**: only when you need separate contexts or deliberately separate roles (for example the checker kept apart from the fixer). Never because it "looks modern".

Each rung up is paid for in cost, latency and debugging difficulty. Climb only when the rung below has been measured as insufficient.

One exception is already backed by evidence and needs no measurement first: queries over heterogeneous models (IFC from many sources, parameter names that differ per project). There, always start with a D step that lists the model's real schema before A generates a query, or use pattern P10 with iteration.

## How to record the scoring

One row per sub-task, with exactly these columns (reused in the Architecture Brief):

| # | Sub-task | Stage | Mode | Reason (which Q) | Output contract | How it is checked |
|---|---|---|---|---|---|---|
| 1 | Interpret the question "which walls have no Fire Rating?" | Interpret | A | Q4 | `QuerySpec{category, filter[], fields[]}` | Schema validation + category enum |
| 2 | Filter elements by the QuerySpec | Read | D | Q2, Q6 | `Element[]` with stable IDs | Unit tests on a planted-defect model |
