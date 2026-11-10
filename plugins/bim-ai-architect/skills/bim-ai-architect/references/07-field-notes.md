# 07 - Field notes: the evidence behind the rules

Read this when you need to convince someone (or yourself) why a rule exists. Two sources: (1) BIM AI systems the author has built and run in production; (2) public open-source projects and papers, surveyed in November 2026. Percentages are as of that survey; check the source before quoting them elsewhere.

## 1. Lessons paid for while building

**A deterministic core, with the LLM as an add-on layer behind a flag.**
The automated checking system works best when the check-fix loop contains no LLM at all; the LLM is used only offline, to turn regulation PDFs into rules. The three LLM roles added later (fix suggestions, diagnosis, orchestration) can all be switched off, and with them off the result is byte-for-byte identical. → `04` section 5, rule 1.

**"The LLM never holds the pen."**
Rules the LLM drafts from natural language must pass the rule validator, then one more barrier at run time (a cap on rule count, a cap on regex length, lookup table names that are identifiers only). The LLM's fix proposals are re-checked by the same rule that found the problem; if they fail, they go to a person. → P3, P9, `04` section 5 rule 2.

**An advisory role that is not enforced is not advisory.**
An independent review found that the LLM orchestration role, "advisory only" on paper, could in practice wipe the list of findings and fake the coverage figures, because the core did not stop it. In the same review: a network error in an advisory role stopped the whole check *after* the model had been written to. → `06` SM4, SM5.

**Sign-based checklists are not enough; trace the paths.**
When an older version of this same system was reviewed against the checklist, the worst defects (a cache bypassing the validator, a network error crashing the run after writing, approvers seeing only part of what would be written) only showed up when tracing the call path, the error path and the approval path. Searching by function name made every gate look "present". → the five path traces in `06`.

**A green core test suite does not protect the LLM layer.**
An LLM layer released separately was changed while the core test suite stayed green. That led to a compatibility check at wiring time; a layer that does not match falls back to the deterministic path. → `04` section 5.

**Where the money goes.**
One check run with the LLM enabled used about 28 thousand small-model tokens (roughly 0.05 USD). About 91% of that went to the diagnosis role, which changes no result at all. Without measuring per role, nobody would have seen it. → `06` LA9.

**Do not loosen the validator to let an LLM case pass.**
A set of 63 natural-language phrasings for the same group of rules: when a few cases failed, the right fix was the prompt. Loosening the validator means flipping verdicts somewhere else. → `06` SM2.

**The LLM does not compute coordinates or distances.**
The spatial checking engine follows "the LLM proposes, the symbolic side checks". The LLM only classifies room function, with a keyword fallback. In the egress code pack, LLM classification is switched off entirely: one wrong room function once flipped three corridor verdicts. An "interior/exterior" attribute declared by a person in the model is not treated as truth either; it is only compared against the geometry. → Q2, Q3.

**Compiler: the spec is the single source of truth.**
The townhouse compiler builds the model from a house spec; nobody edits in the authoring software and syncs back. Each build goes into a fresh copy of the seed file. After building, a read-back gate compares every element with the plan, to a 1 mm tolerance. → P2.

**Extraction: reject, never coerce.**
The rule extractor for regulation text: the LLM only extracts and interprets, through a forced tool call; output with the wrong schema is discarded rather than patched to fit; confidence below 0.75 forces human review; only rules marked "executable" become YAML. The schema has one source, the copies in other repositories are generated and have a sync test; that test has already caught real drift. → `06` SM3, SM7.

**Text and rules are two layers.**
A regulation catalog: the LLM extracts clauses (in batch), then code matches every quote against the PDF's text layer (exact / near / fuzzy / not found; not found means not used). The stated limit: a matching quote does not prove the numbers and conditions were interpreted correctly. That part still needs a person. → P3.

**A deterministic referee for negotiation.**
A clash negotiation system: evidence put forward by an agent is checked by code, not graded by an LLM ("model grading model is not repeatable"). If the LLM agent fails, it retries once and then falls back to the rule agent behind the same interface, and the UI shows which one ran. Structured knowledge packs come first, RAG second. The mediator's draft is shown but not preselected. → `04` section 5 rule 6, `06` LA8, WR5.

**The write gate lives in the server.**
The CDE adapter: authentication → allow-list → read-only check → rate limit → business rules → dry run → de-duplication → approval token (valid 300 seconds, single use, bound to the payload hash) → execute → hash-chained log. The reason recorded in the design decision: LLMs can invent API payloads. The Revit adapter: one batch is one transaction, the first error rolls back; there is a preview-required mode (no token returns 428, a mismatch returns 409); read-back results are in the response; warnings are returned as data, and the resolution the software suggests is only reported, never applied. → P8, `04` section 2.

**Too many tools make the agent choose badly.**
The Revit adapter has more than 100 tools; tool-selection accuracy dropped. The fix: profiles per role, and read-only recipes that package already-verified command chains. → P7, `06` AR3.

**Benchmarks that fool themselves.**
The first benchmark saturated (strong and weak models both scored 1.0) because the answers leaked through element names. With neutral names: strong model 1.0, small model 0.685, with 2 invented IDs. The score is multiplied by a discipline factor so that an unapproved write cannot be bought back by good results. No LLM decides a benchmark verdict. → `06` EV2, `05` section 1.

**Stop building the "brain".**
A central LLM orchestration project was stopped once a general agent plus MCP servers did exactly that job, and the software vendor was shipping that layer too. What was kept is the safety posture (dry run, approval, log); unattended work moved to a deterministic nightly job. → `06` AR4.

## 2. Open-source projects worth reading (and what they teach)

| Project | How A / D is split | Lesson |
|---|---|---|
| [`IfcOpenShell/IfcOpenShell`](https://github.com/IfcOpenShell/IfcOpenShell/tree/v0.8.0/src/ifcmcp), `src/ifcmcp` | The model supplies selectors and API paths; the kernel handles types, quantities, validation, clashes. Compact references, depth truncation, saving the file is a separate step | Selector language + truncation + explicit commit |
| [`bimwright/rvt-mcp`](https://github.com/bimwright/rvt-mcp) | The server enforces: schema validation, binding to the target document, rollback on warnings by default, read-only mode, a response size cap, code submission compile-only | Put safety in the server; prompt-level confirmation is only advice |
| [`oakplank/RevitMCP`](https://github.com/oakplank/RevitMCP) | 46 tools, none of them for arbitrary code. Query results kept server-side and returned as handles; delete has dry run + confirmation + a count cap | Keep large result sets out of the context |
| [`mcp-servers-for-revit/mcp-servers-for-revit`](https://github.com/mcp-servers-for-revit/mcp-servers-for-revit) | The model picks tools; fixed C# commands execute. Includes a tool that sends arbitrary C# code | An arbitrary-code tool erases the boundary; it needs its own gate |
| [`JotaDeRodriguez/Bonsai_mcp`](https://github.com/JotaDeRodriguez/Bonsai_mcp) | Measurement rules, a price table and cost export live in code; the model orchestrates and writes the report | Quantities and prices never come from the model |
| [`dcy0577/Text2BIM`](https://github.com/dcy0577/Text2BIM) | Agents write code against a curated toolset; a commercial rule checker feeds errors back into the loop | A deterministic checker as the "critic" of the generation loop |
| [`Tsesterh/Text2BIM-Self-Verification`](https://github.com/Tsesterh/Text2BIM-Self-Verification) | Requirements are split: what IDS can express is checked by IfcTester; the rest is checked by an LLM with read-only tools | Route each requirement to the checker that can express it |
| [`ZihanDDD/BIMgent`](https://github.com/ZihanDDD/BIMgent) | The LLM plans and supervises (at most 3 retries); a segmentation model + geometric post-processing extract the walls; a "pure-action" builder replays precomputed coordinates | Even a GUI-driving agent keeps coordinates out of the LLM |
| [`sylvainHellin/cobbie`](https://github.com/sylvainHellin/cobbie), `ifc-bench` | An agent explores IFC iteratively with IfcOpenShell code | Adaptive exploration 55-57% versus static query generation 17-21% ([paper](https://arxiv.org/html/2605.01698)) |
| [`nomic-ai/aec-bench`](https://github.com/nomic-ai/aec-bench) | Agents run in sandboxed Docker environments; their outputs are verified automatically | Retrieval is often the bottleneck, before reasoning even starts ([paper](https://arxiv.org/html/2603.29199v1)) |
| [`ludolara/floor-plan-rlvr`](https://github.com/ludolara/floor-plan-rlvr) | The LLM generates JSON polygons; code computes the score (parses, no overlap, connected, area) | A deterministic checker as the training signal |
| [`humanlayer/12-factor-agents`](https://github.com/humanlayer/12-factor-agents) | General guidance | Good agents are "mostly just software": you own the control flow, tool calls are structured output your code handles, people are contacted through a tool |

## 3. Where LLMs fail on BIM data (according to public benchmarks)

- **Units and summing:** numeric tasks score consistently low; models apply the wrong quantity definition or the wrong unit scale ([BIBIMBAP](https://ec-3.org/wp-content/uploads/2026/08/EC32026_271.pdf)).
- **Relationship integrity:** a door is deleted but its opening is left behind; integrity is the most challenging criterion for every model ([BIBIMBAP](https://ec-3.org/wp-content/uploads/2026/08/EC32026_271.pdf)).
- **Editing IFC with self-written code:** the best model reaches about 50% on suites of 100 to over 300 tasks; the rate of fully completing a task is very low ([BIBIMBAP](https://ec-3.org/wp-content/uploads/2026/08/EC32026_271.pdf), [BIM-Edit](https://arxiv.org/html/2606.20146)).
- **Geometry when generating models:** walls not joined, missing openings, rooms without IfcSpace, elements often without psets, furniture without containment relations ([MCP4IFC](https://arxiv.org/html/2511.05533v1)).
- **Silent semantic errors:** code runs without errors but means the wrong thing (building height = highest elevation); invented tables/columns ([source](https://arxiv.org/html/2605.13236)).
- **Token blow-up:** broad queries overflow the context beyond recovery ([source](https://arxiv.org/html/2605.13236)); the definitions of 50+ tools alone cost about 40 thousand tokens ([MCP4IFC](https://arxiv.org/html/2511.05533v1)).
- **Static schema assumptions:** property names change with language and project; data sits in unexpected psets ([source](https://arxiv.org/html/2605.01698)).
- **Formalising regulations:** generated rules that are syntactically valid but semantically wrong (a building's function applied to a room), hard to spot even in diagrams ([source](https://ec-3.org/wp-content/uploads/2026/08/EC32026_355.pdf)); natural language → IDS: the best "content pass rate" is only about a third ([Ishigaki-IDS-Bench](https://arxiv.org/abs/2605.22079)).
- **Drawings:** defects that can be caught from the text are found nearly 100% of the time, defects that need looking at the drawing about 5% ([AEC-Bench](https://arxiv.org/html/2603.29199v1)).

## 4. Where "the LLM interprets, code decides" needs a footnote

The original rule still holds for the judging path and the write path. But the evidence suggests four adjustments:

1. **Rigid pipelines lose on heterogeneous models.** Letting A explore iteratively (in a read-only sandbox) beat one-shot query generation by about 37 points; a weaker model allowed to explore even beat a stronger model run statically ([source](https://arxiv.org/html/2605.01698)). The *Read-Interpret* part should be more adaptive than we assumed. → P10, the limit of P1.
2. **Deterministic deciders have blind spots.** IDS cannot express every requirement; SHACL is binary and cannot separate a violation from missing data ([source](https://ec-3.org/wp-content/uploads/2026/08/EC32026_355.pdf)). What falls outside their coverage needs A or a Human, and must carry a different label (`manual_review`), never mixed into PASS/FAIL. → Q3, the four statuses.
3. **A can *write* the decider.** Generate checking code, test it on elements experts have labelled, then run it deterministically. In the same study, a fixed loop still beat an LLM orchestrating itself, on one benchmark ([ARCHER](https://www.alphaxiv.org/abs/2607.25566)). → P3 in its strong form.
4. **Adding deterministic tools is not always better.** Parsing tools lowered scores on tasks that need looking at images ([AEC-Bench](https://arxiv.org/html/2603.29199v1)); a hand-made toolset made a weaker model loop ([source](https://arxiv.org/html/2605.01698)). Tools must be measured with evals like everything else. → `05`.

On LLMs as judges, the evidence is mixed (in some places more consistent than experts, in others expensive and unreliable). The practical rule: let code grade whenever code can grade.

## 5. Background reading

- Anthropic, *Building effective agents*: workflows versus agents; chaining, routing, orchestrator-workers, evaluator-optimizer. [`anthropic.com/engineering/building-effective-agents`](https://www.anthropic.com/engineering/building-effective-agents)
- Anthropic, *Writing tools for agents*: few tools, merged chains, pagination, errors that say how to fix them. [`anthropic.com/engineering/writing-tools-for-agents`](https://www.anthropic.com/engineering/writing-tools-for-agents)
- Anthropic, *Code execution with MCP*: the model writes code that filters data in a sandbox. [`anthropic.com/engineering/code-execution-with-mcp`](https://www.anthropic.com/engineering/code-execution-with-mcp)
- Anthropic, *Demystifying evals for AI agents*: code-based graders where possible, grade the end state, run several trials, start from 20-50 real cases. [`anthropic.com/engineering/demystifying-evals-for-ai-agents`](https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents)
- HumanLayer, *12-factor agents*. [`github.com/humanlayer/12-factor-agents`](https://github.com/humanlayer/12-factor-agents)
- Benchmarks: BIBIMBAP (CRUD on IFC), BIM-Edit, ifc-bench, AEC-Bench, Ishigaki-IDS-Bench.
