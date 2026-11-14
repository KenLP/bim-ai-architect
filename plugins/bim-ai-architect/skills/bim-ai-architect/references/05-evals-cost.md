# 05 - Measuring quality and keeping cost down

The D part is checked with unit tests. The A part is checked with evals. Without both, every change of prompt, model or rule is a change made blind.

## 1. Three kinds of checks

| Kind | What it checks | Data | When it runs |
|---|---|---|---|
| **Deterministic checks (unit)** | Engine, rules, compiler, contracts | Planted-defect model: you planted the defects yourself, so you know the answers | Every commit. It is a blocking gate |
| **Evals for the adaptive part** | Interpretation, extraction, classification, rule authoring | A gold set of real cases with answers labelled by people: start with 20-50 cases, grow to 100-200 | Every change of prompt/model/schema |
| **Live run** | The whole chain on the real software and a real model | A project model (a copy) | Before release; periodically |

### Planted-defect model
- Take a clean model and plant N known defects (narrow doors, missing parameters, wrong names, clashes). Keep the list of defects as the answer key.
- Measure: how many of the N are caught (recall), how many false alarms (precision). These two numbers are the quality of the checker.
- Plant *near-threshold* and *missing-data* cases too, to test `manual_review` and `missing_data`.
- For apps that work on a CDE or on documents, the "planted-defect model" is a sandbox project seeded with cases whose answers are known (duplicate and near-duplicate issues, wrong owners, requirements that contradict each other).
- For *generators* (compiler, grammar, solver) there are no "defects to find"; the equivalents are: planted bad inputs (a wrong spec must be rejected with the right code), parameter sweeps (every combination in scope gives a valid result or `infeasible`), and golden hashes (the same spec gives the same result).

### Gold set for the adaptive part
- Take it from real cases (questions users actually typed, real family names, real clauses); do not invent tidy ones.
- If people label the answers: have two people label independently and measure agreement (kappa). Low agreement means the criterion is unclear; fix the criterion before blaming the model.
- Score with code where you can (compare JSON, compare enums, compare ID sets). Use an LLM as judge only for prose, and check the judge on a few dozen cases people have scored.
- Hold back part of the gold set that never goes into prompts or few-shot examples, so you are not grading what the system has already seen.

### Live run
- Check the environment first (the software is open, the right model, the adapter answers). If something is missing, record the run as blocked with the reason instead of running anyway; `missing_data` is for elements, not for runs.
- Catches what mocks hide: units, timeouts, non-ASCII text, missing parameters, dialogs.
- A silent system is not a pass. Beyond the four Finding statuses, the checker must recognise "no response" at run level and never read it as compliant.

## 2. Metrics worth tracking

| Sub-task | Metric |
|---|---|
| Interpretation → QuerySpec | Share of specs that are entirely right; share of clarifying questions asked at the right moment |
| Extraction / classification | Precision and recall per class; share that falls to Human approval |
| D verdicts | Recall and precision on the planted-defect model; number of `missing_data` cases |
| Model generation | Share of specs valid on the first attempt; read-back deviation from the spec; share of the user's wishes met; how different the options are from each other; hours of manual editing after generation |
| Automatic fixes | Share of fixes that introduce no new defect; rounds needed to converge |
| Presentation | Share of numbers in the text that trace back to a Finding (must be 100%) |
| The whole chain | Task completion rate, time, cost per run |

Before optimising, measure a **baseline**: (a) D only, no A; (b) one LLM call, no agent. Many features that "need an agent" turn out to be covered by the baseline.

## 3. Cost and latency

**Principle: spend tokens on what is ambiguous, spend CPU on what is already clear.**

| Lever | How |
|---|---|
| Fewer calls | A writes once, D runs N times (Q6). Batch similar work into one call with structured output |
| Smaller context | Tools return compact results; large data stays on the machine side (P10); include only the relevant parameter/category names |
| Ratchet | A decisions that have stabilised → lookup table/keyed cache (P5). Track the share of cases that still need A; it must keep falling |
| Pick the model per task | Small, fast models for high-volume extraction and classification. Strong models for planning, rule authoring, complex specs. Changing model must go through the evals |
| Prompt caching | Put the fixed part (schema, catalogs, instructions) at the start of the prompt so it can be cached |
| Batch processing | Work that needs no immediate answer (overnight classification, rule authoring) goes through batch |
| Agent limits | Caps on rounds and tokens, and a stop condition D can check |

Model prices and names change often: look up the provider's documentation at design time, and do not hard-code them into the architecture.

## 4. Observability

Every run records: the input, the QuerySpec/spec A produced, the code that ran (for P10), the tools called and their results, the Findings, the ChangeSet and who approved it, and the versions of model/prompt/rule pack/engine.
The goal: six months later, when someone asks "why did it flag this door as non-compliant that day", you can answer without rerunning the LLM.

## 5. The maturity ladder for a feature

| Level | State | Condition to move up |
|---|---|---|
| 0 | Trying it out in a sandbox, A does almost everything | 20-50 real cases logged |
| 1 | Scored with the rubric, contracts between A and D | A gold set + a planted-defect model |
| 2 | Judging and writing are D, with a write gate | Evals run automatically; a baseline exists |
| 3 | Running on other people's real models | Live run green; logs and read-back complete |
| 4 | Outside users use it regularly | Cost tracked, the A share keeps falling |

Do not skip levels: handing a level 0 feature to clients is the fastest way to lose trust in the whole product.
