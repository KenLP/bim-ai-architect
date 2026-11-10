# 06 - Anti-patterns and a checklist for reviewing an existing app

Used in `review` mode, and to self-check an Architecture Brief before handing it over. Violation codes are two letters + a number (LA, DC, SM, WR, EV, AR) so they are not confused with the mode symbols D/A/H/Human. Each item: the sign you can spot in the code/design → why it fails → how to fix it. Severity: 🔴 blocks release · 🟠 fix soon · 🟡 tech debt.

Two severity rules:
- **Raise one level** when the defect can strike *after the model/CDE has been written to*, or when it falsifies what the approver sees.
- **Latent violations** (the design allows it but the configuration in use does not reach it yet): still report it, mark it "latent", lower it one level.

The checklist is only a list of signs. The worst defects rarely show in function names; they show in *paths*: run all five path traces at the end of this file before concluding.

## 1. Adaptive in the wrong place (code LA)

| # | Severity | Sign | Why it fails | Fix |
|---|---|---|---|---|
| LA1 | 🔴 | The LLM returns numbers (area, totals, distances) or converts units itself | Wrong but plausible, nobody notices | Numbers come only from D tools; check that the text traces back to data (P6) |
| LA2 | 🔴 | The LLM gives PASS/FAIL for a threshold check; the clauses live in the prompt | Not repeatable, not explainable | Rule pack + engine (P3); A only explains |
| LA3 | 🔴 | The LLM calls write commands directly, with no preview and no approval | A damaged model that cannot be reverted | Write gate (P8) |
| LA4 | 🔴 | A "run arbitrary code" tool inside the authoring software, with the same permissions as ordinary tools | Erases every safety boundary that was built | Keep it separate, off by default, compile-only or a read-only sandbox |
| LA5 | 🟠 | One LLM call per element; raw model data dumped into the context | Expensive, slow, context overflow, the model misses things | A writes once, D runs N times (Q6, P10) |
| LA6 | 🟠 | The LLM writes coordinates, element IDs, GUIDs | Invented IDs, accumulating geometric errors | Semantic spec + compiler (P2); IDs only chosen from a list D provides |
| LA7 | 🟠 | An agent/multi-agent setup for a process that is already fixed | Paying for cost and uncertainty you do not need | A workflow; measure a baseline first |
| LA8 | 🟠 | One LLM grades another LLM's evidence/output when code could check it | Model grading model, not repeatable | A D validator; LLM judges only for prose, calibrated |
| LA9 | 🟡 | Most of the tokens go to diagnostic prose that changes no result | Money spent where it creates no value | Measure tokens per role; cut it or make it on-demand |
| LA10 | 🟠 | A changes the status or exit code of the whole run (for example A says stop early and the run is recorded as "converged") | Readers think the work is done, when in fact a model just said stop | Record a separate `stop_reason`; "A stopped early" is not "converged"; show it in the report and the run record |

## 2. Deterministic in the wrong place (code DC)

| # | Severity | Sign | Why it fails | Fix |
|---|---|---|---|---|
| DC1 | 🟠 | Piles of regex/if-else to understand user sentences or carelessly chosen names | Never covers everything, breaks on the next project | A at the Interpret stage, closed enums (P1, P5) |
| DC2 | 🟠 | A rigid query pipeline that assumes fixed parameter/pset names | Real models are heterogeneous | A schema discovery step, or P10 with iteration |
| DC3 | 🟡 | A D engine forced to give PASS/FAIL on a qualitative clause | A falsely precise verdict | `manual_review`, A gathers evidence, Human decides |
| DC4 | 🟡 | Hand-written rules for hundreds of clauses that nobody has time to maintain | Rules go stale silently | A drafts with citations, Human approves, tested against examples (P3) |

## 3. Weak seams (code SM)

| # | Severity | Sign | Why it fails | Fix |
|---|---|---|---|---|
| SM1 | 🔴 | A and D exchange free text, parsed with regex | Breaks when the model changes its wording | Structured output + schema + validation |
| SM2 | 🔴 | Loosening the validator so one LLM case passes | Equivalent to flipping the verdict for every other case | Fix the prompt or the schema; the validator is fixed |
| SM3 | 🟠 | Wrong-schema output is "coerced" into passing | Semantic errors leak downstream | Reject, return structured errors, allow at most k repair rounds (P9) |
| SM4 | 🟠 | The LLM's "advisory only" role exists only in the docs; the core takes A's whole result and merges it into state. This includes in-house plugins running in the same process | One bad output deletes Findings, fakes coverage, or rewinds the loop counter | The core accepts only allow-listed keys from each role; test it with a destructive fake A |
| SM5 | 🟠 | A failure in the A layer (network, timeout) stops the whole run, especially after writing | The model is left half-changed | Isolate A's failures; D carries on |
| SM6 | 🟠 | Only two statuses, pass/fail; missing data is counted as pass or as fail | The report is wrong in both directions | Four statuses |
| SM7 | 🟠 | Enums and schemas copied by hand into another repo | Silent drift | One schema source, generated copies, a sync test with a hash |
| SM8 | 🟠 | The run record cannot answer: was A enabled, was the plugin present, which model, how many calls succeeded/failed/were blocked, which values A produced (`origin`). Figures are only printed to the console | Two runs cannot be compared; nobody knows whether the approver is looking at a model's guess or a deterministic value | An `llm` block in the run metadata; keep the spec/code A produced |
| SM9 | 🟡 | Silent retries around LLM calls | Called twice, costs money, hides errors | Explicit retries, counted and logged |
| SM10 | 🔴 | A cache/memo/fallback path returns A's value without going through the validator; the cache key lacks context the validator uses | A value valid for one element is given to another (a door in a 4-hour wall gets the rating meant for a 1-hour wall) | Every path that returns a value goes through the validator; the cache key includes all of the validator's inputs |
| SM11 | 🟠 | A vacuous verifier: the rule used to check A's proposal only checks form ("has a value", correct format) | Wrong values in the right form are accepted; with a "not empty" rule everything passes | Limit which kinds of rules accept proposals from A; check value type and size in the core |
| SM12 | 🟠 | A's batch answers are not tied to the elements asked about (IDs not matched) | The model permutes values between elements and every one of them looks valid | Every answer carries an ID; the core compares it with the IDs it asked about and rejects mismatches |
| SM13 | 🟠 | Strings written by third parties (family names, rule descriptions from PDFs) go straight into the prompt | Instructions injected through model data | Fence/escape outside strings and treat them as data |
| SM14 | 🟠 | An A layer released separately with no version handshake or contract check at wiring time | Present-but-mismatched causes failures mid-run; the core tests stay green | Check version and shape at start-up; on mismatch fall back to D |
| SM15 | 🟡 | Metering can be bypassed: failed calls recorded as successes, a fallback that calls twice counted once, a cap of 0 meaning unlimited | Cost and reliability are reported wrongly | Count at a single point every call must pass through |

## 4. Leaky write paths (code WR)

| # | Severity | Sign | Fix |
|---|---|---|---|
| WR1 | 🔴 | Confirmation exists only at prompt level ("ask the user before deleting") | The gate lives in the server/adapter; the prompt is only advice |
| WR2 | 🔴 | The approval token is not bound to the payload; content can still change after approval | Token bound to the payload hash, single use, with an expiry |
| WR3 | 🟠 | One batch of changes becomes N transactions | One batch = one undo step; the first error → roll back the whole batch |
| WR4 | 🟠 | No read-back; trusting the API's return code | Read back and compare with the ChangeSet |
| WR5 | 🟠 | Automatically applying the "resolution" the software suggests for a warning; preselecting the option A proposed | Return warnings as data; a person chooses |
| WR6 | 🟠 | No cap on the number of changes per run | Rate limit + max-count in the server |
| WR7 | 🟡 | Experimenting on a real project model | A copy; open without editing, close without saving |
| WR8 | 🔴 | Approval covers content that is not shown: the token covers the whole batch but what the approver sees is truncated or summarised | Every change in the batch is present in what gets approved (split the batch to fit, or attach the full table) |
| WR9 | 🔴 | The approval surface does not say which values A produced, or says they were "computed" | A's origin label and rationale appear on *every* approval surface, not only the main UI |
| WR10 | 🟠 | Loose approval semantics: an everyday action (changing an issue status) is read as approval; who approved is not recorded | A separate, explicit approval action; record the approver's identity |

## 5. Missing measurement (code EV)

This group needs history and eval results. With only a code snapshot, write one line, "EV group cannot be assessed, needs: gold set, baseline results", instead of listing each item.

| # | Severity | Sign | Fix |
|---|---|---|---|
| EV1 | 🔴 | Changing the prompt/model without a gold set | 20-50 real cases first, then grow |
| EV2 | 🟠 | A benchmark whose answers leak through element names (every model scores 100%) | Neutral names; check by comparing a strong and a weak model |
| EV3 | 🟠 | Scoring a single run | Run several times; for work that must be stable, require it to be right every time |
| EV4 | 🟠 | No "A switched off" baseline | A flag that turns A off; compare results and cost |
| EV5 | 🟡 | Answers proposed by the model then used as ground truth | Answers declared before the run; labelled by people, kappa measured |
| EV6 | 🟡 | Unknown cost recorded as 0 | Record `null`; measure real tokens per role |

## 6. Architecture and product (code AR)

| # | Severity | Sign | Fix |
|---|---|---|---|
| AR1 | 🟠 | Rules/standards scattered across adapters, UIs, prompts, several repos | One rule pack; everything else generated from it |
| AR2 | 🟠 | The verdict core calls the authoring software/CDE directly | The core receives extracted data; the adapter handles I/O |
| AR3 | 🟠 | 100+ tools for one agent | Profiles per role, recipes, merged chains |
| AR4 | 🟡 | Building your own orchestration "brain" that does exactly what a general agent + MCP already does | Put the effort into what vendors do not ship: domain engines, rules, data, safety gates |
| AR5 | 🟡 | A feature at the experimental level handed straight to clients | Follow the maturity ladder (`05-evals-cost.md` section 5) |
| AR6 | 🔴 | The model-provider switch fails open (a mistyped name → falls back to a default cloud), silently sending project data off the machine | An allow-list; unknown values stop the run |
| AR7 | 🟠 | A mistyped flag for enabling A → the run proceeds without A and says nothing, so users believe A took part | Unknown flag values raise a warning; compare "the configuration needs A" with "A was actually built" |
| AR8 | 🟡 | Docs or docstrings promise a guarantee the code does not provide | Every guarantee has a test; no test, delete the sentence |

## Five path traces (run them before concluding)

1. **Error path.** From each LLM call, trace which exception types can escape and how far. Are network errors in the adapter wrapped? If one fires after the first write, are the run record and the report still written?
2. **Validator-bypass path.** Find every path that returns a value from A: single calls, batch calls, cache/memo, fallback. Every one must go through the same validator.
3. **State path.** What does the core accept from each A role, and how does it merge it into state? Can an advisory role overwrite Findings, coverage, counters?
4. **Approval path.** Compare what the approver *sees* with what will be *written*: is it truncated, does it carry the origin label, who counts as having approved.
5. **Evidence path.** Open the run record and the report: from those alone, can you tell whether A ran, which model, how many errors, why it stopped? Compare the promises in the docs with the code.

One more trace for configuration: for every switch related to A (provider, enable flag, budget cap), in which direction does it fail when mistyped?

## How to report a review

1. The as-is task-split table, five columns: sub-task · stage · mode in use · mode the rubric recommends · notes. Include what is already done right and verified in the code.
2. The list of violations using the codes above, each with `file:line` evidence and one sentence on the concrete failure it allows, ordered by severity. Real defects with no code are marked "outside the checklist".
3. The three highest-leverage changes, each stating: what to change, and what to measure to know it got better.

Do not report a violation without having opened the code; if unsure, write "needs checking". When reviewing part of a system, say which parts were treated as a black box.
