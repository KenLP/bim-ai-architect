# 02 - Ten patterns for combining deterministic and adaptive

Each pattern answers: where A sits, where D sits, which contract they talk through, and the usual trap. Choose patterns after scoring the sub-tasks with `01-rubric.md`. An app usually combines 3-5 patterns.

## Quick choice

| You are building | Pattern |
|---|---|
| Q&A / querying the model in natural language | P1 Interpret → Execute, P10 Write query code |
| Generating a model from a brief / drawings | P2 Compiler |
| Code compliance checking | P3 Author rules offline, P6 D verdict + A words |
| Proposing options (clashes, layout, pipe routes) | P4 Propose → Check → Choose |
| Classifying / mapping / cleaning naming data | P5 Rules first, A for the remainder |
| Free-form assistant inside Revit / the CDE | P7 Agent + tools + recipes, P8 Write gate |
| A produces something that can be test-run | P9 Generate-check loop |

---

## P1. Interpret → Execute (A at the edge)

```
natural language ──A──▶ Intent/QuerySpec (JSON, closed enums) ──D──▶ result ──A──▶ answer
```
- **Use when:** the input is natural language and the real work is a known query or command.
- **Contract:** a schema with closed enums for category, operator and parameter name (taken from the model, A may not invent them); units stated explicitly; a `needs_clarification` field so A is allowed to ask back.
- **Trap:** letting A return the element list or the numbers directly. A returns only the *query spec*; D fetches the data.
- **Limit:** a one-shot QuerySpec built on an assumed schema breaks on heterogeneous models (the parameter is `Width` in one project and `Breite` in another, data sits in an unexpected pset). Give A a *discovery* step first (a tool that lists the parameters/categories that actually exist in this model) and only then generate the QuerySpec; or switch to P10 with iteration.
- **BIM example:** "which level 3 walls are missing a Fire Rating" → `{category: Walls, level: "L3", filter: [{param: "Fire Rating", op: "is_empty"}]}`.

## P2. Compiler (A generates the spec, D builds the model)

```
brief / drawings ──A──▶ intermediate spec (DSL with a schema) ──D validate──▶ D compile ──▶ model ──D read-back──▶ matches spec?
```
- **Use when:** you need to create or change many elements that are geometrically related.
- **Contract:** an intermediate spec that carries domain meaning (rooms, grids, levels, which door connects which rooms), not a list of API calls. The spec can be validated before it touches the model.
- **You usually need two specs, not one.** The *intent spec* (plot, number of storeys, number of rooms, wishes from an enum) is what A may write. The *geometric spec* (coordinates, polygons, IDs) is written only by a solver/grammar/compiler. The full flow: spoken words ──A──▶ intent spec ──D generates──▶ geometric spec ──D compiles──▶ model. A never writes the geometric spec, not even to iterate on validator errors (hard rule 4).
- **Why:** A is good at intent and bad at coordinates. The compiler handles coordinates, constraints and creation order. The same spec rebuilt gives the same model.
- **Trap:** letting A call `create_wall` 200 times with coordinates it made up. Errors accumulate, nothing is repeatable, nothing can be diffed.
- **Mandatory:** read-back after building (count, measure, compare with the spec), because an API that ran without errors does not mean the model is right.

## P3. Author rules offline, run rules online

```
(design time)  regulation text ──A──▶ draft rule with citation ──Human approves + tests──▶ rule pack (versioned)
(run time)     model ──D rule engine + rule pack──▶ verdict
```
- **Use when:** checking compliance against standards, EIR, BEP.
- **Contract:** each rule has a stable ID, a clause citation, units, scope, severity, and examples that pass and fail. The source text and the executable rule are two separate layers.
- **Why:** an LLM at *design time* is reviewed by a person once and reused forever. An LLM at *run time* is a fresh risk on every run, and the verdict cannot be repeated.
- **Trap:** stuffing the clauses into a prompt and asking "does this model comply?". Nobody can reproduce that result.

## P4. Propose → Check → Choose (generate and test)

```
problem ──A or solver──▶ N options ──D validator──▶ valid options + scores ──Human or D policy──▶ choose
```
- **Use when:** the solution space is large but *checking one solution is cheap* (clash resolution, routing, floor layout).
- **Who generates:** the space can be enumerated or a solver exists → D generates and scores; only otherwise does A generate. See `01-rubric.md`, section "Who generates the options?".
- **Contract:** an option is data (a change delta), and the validator returns the reason for rejecting it. Only options that pass the validator reach a person. The choice belongs to a person, or to a D policy table a person approved; A may rank and explain, not choose.
- **Trap:** trusting an option that A claims has "no clashes left". Check it with real geometry, ideally previewed on the model, before writing.

## P5. Rules first, A for the remainder (cascade + ratchet)

```
input ──D rule/lookup table──▶ matched (≈80-95%) ──▶ done
                └─ no match ──A classifies (closed enum + confidence)──▶ Human approves (low confidence first)
                                              └─ approved result ──▶ added to lookup table (D handles it next time)
```
- **Use when:** mapping family names to a classification, normalising parameter names, recognising room types from names, joining data from two sources.
- **Contract:** A may only choose from the enum, with `confidence` and `evidence`. The lookup table is versioned. A row proposed by A joins the table only after a person approves it, whatever its confidence.
- **Why:** cost falls over time, behaviour becomes more and more deterministic, and unusual cases are still handled.
- **Trap:** sending 100% through A "to be safe". Expensive, slow, and it loses repeatability on the part that was already certain.

## P6. D verdict, A words (presentation never recomputes)

```
D engine ──▶ Finding (rule_id, element_id, measured value, threshold, status) ──A──▶ explanation, summary, letter
```
- **Use when:** inspection reports, summaries for management, drafting issues/RFIs.
- **Contract:** a standard verdict record (see "Finding" in `04-contracts-guardrails.md`). A receives the record and may only *rephrase* it.
- **Rule:** every number and status in the text must trace back to a field of a Finding. This can be checked by machine: extract the numbers from the answer and compare them with the source data.
- **Trap:** A "helpfully rounds", sums totals on its own, or turns "needs review" into "compliant" to keep it short.

## P7. Agent + deterministic tools + recipes

```
goal ──A (loop)──▶ choose tool ──D tool──▶ result ──▶ … ──▶ stop when a checkable condition holds
                    └── chain repeated many times ──▶ packed into a recipe (1 tool that runs the whole D chain)
```
- **Use when:** open-ended tasks where the number of steps is unknown in advance (exploring a model, investigating a bug, interactive support).
- **Contract:** small tools with clear names that return summarised data (counts, groups, pages) instead of raw dumps; errors returned as data with a suggested next step; tools grouped into profiles so the agent does not choose among 100 tools.
- **Ratchet:** when the agent keeps repeating the same chain of 4-5 tools → write a deterministic recipe. The agent is left with choosing the recipe.
- **Trap:** using an agent for a process that is already fixed. A workflow is cheaper, faster and measurable.

## P8. Write gate

```
A proposes values ──D validate + scope check──▶ preview (dry run by default) ──Human (or policy) approves──▶ execute in 1 transaction
        ──▶ read-back ──▶ log ──▶ software warnings returned as data
```
- **Use when:** any change to the model, the CDE, an issue, a file.
- **Contract:** dry run is the default; the approval token is bound to the exact payload (change the payload and the token is void); a whole batch is one undo step; an automatic policy by severity (do it automatically / needs approval / only a person does it), where automatic covers only cases identical to ones a person approved before.
- **Trap:** "just this once, write directly". Details: `04-contracts-guardrails.md`.

## P9. Generate-check loop (evaluator loop)

```
A generates ──▶ D checks (schema, compile, test, validator) ──structured errors──▶ A fixes ──▶ … (at most k rounds) ──▶ Human if it still fails
```
- **Use when:** A generates a spec, rule, query or code, and there is an automatic checker.
- **Contract:** errors returned must be specific (which field, why, what values are valid). Cap the number of rounds. Convergence compares the *set of errors*, not the number of errors (fixing error A can expose error B, so the count stays the same while the set has changed).
- **Trap:** using another LLM as the judge for something whose answer can be checked by code.

## P10. A writes query code, D runs it in a sandbox

```
question ──A──▶ code/query (IfcOpenShell, SQL, pandas, filter DSL) ──read-only sandbox──▶ compact result ──A──▶ answer
```
- **Use when:** varied analytical questions over a large model, where no one can write a tool in advance for every question.
- **Why:** the data stays on the machine side and only a compact result enters the context. Avoids token blow-up and avoids A "skimming" 50,000 rows.
- **Contract:** a read-only sandbox with time and memory limits; the code and its result are kept for explanation.
- **Controlled iteration:** letting A run a few rounds (look at the schema → try → fix) is usually much better than one shot, especially with IFC from many sources. Cap the rounds and the tokens.
- **Trap:** giving that code write access; not keeping the code that ran, so nobody can re-check the answer; trusting the result because the code ran without errors (silent semantic errors, for example taking the highest elevation as the building height). For quantities that matter, use a tested D function instead of letting A write the formula.

---

## Combining patterns: three reference architectures

**Automated checking with fixes (audit + fix):**
`Read (D)` → `Judge (D, rule pack from P3)` → `Decide (policy table + A proposes, P4)` → `Write (P8)` → `Judge again (D)` until it converges → `Present (P6)`.

**Generating a model from a brief:**
`Interpret (A)` → `Spec (P2)` ⇄ `check spec (P9)` → `Compile (D)` → `Read-back (D)` → `Judge against the rule pack (D)` → `Present (P6)`.

**Q&A assistant over a model:**
`Interpret (A, P1 or P10)` → `Read (D)` → `Present (P6)`; if the user asks for a change → hand over to `P8`.
