# Architecture Brief: <app name>

- **Date:** <yyyy-mm-dd> · **Status:** DRAFT | FINAL
- **One line:** <what the app does, for whom, on which platform (Revit / IFC / ACC / …)>
- **Current level → target level:** <0-4, see the maturity ladder; when adding to an existing system, give the new layer and the core separately>

## 1. Context

When adding to an existing system, start with two lists, each line with a path: **Already in the code** · **Only planned** (unexecuted specs, reports). Drop this for a brand-new app.

| Item | Answer |
|---|---|
| Users and what they currently do by hand | |
| Data sources (model, CDE, documents, drawings) and typical size | |
| Does the app WRITE anywhere | |
| Who is accountable for the result; does it have to be explained | |
| Volume and run frequency | |
| Constraints (budget, latency, data that must not leave the machine) | |

## 2. Task-split table (the heart of the brief)

| # | Sub-task | Stage | Mode (D/A/H/Human) | Reason (Q1-Q7) | Output contract | How it is checked |
|---|---|---|---|---|---|---|
| 1 | | Read / Interpret / Judge / Decide / Write / Present / Design-time | | | | |

Expected split: <x> D sub-tasks · <y> A · <z> H · <n> Human.

## 3. Flow diagram

One diagram per way of running (interactive chat, scheduled job, design-time step); delete the ones that do not exist.

```
<ASCII drawing: [square brackets] = D, (round brackets) = A, ◆ = a person approves; name the contract on each arrow>
```

Patterns used: <P1…P10, and where each one is used>.
Rung of the A part: <one call | workflow | agent | multi-agent>, because <reason; what the lower rung lacks>.

## 4. Contracts

Delete the rows you do not use.

| Contract | From → to | Main fields | Schema owner | Validated by |
|---|---|---|---|---|
| QuerySpec / Intent | A → D | | | |
| Intermediate spec | A → compiler | | | |
| Rule pack | Human+A → engine | | | |
| Finding | engine → everywhere | | | |
| ChangeSet | A → write gate | | | |

Units decision: <internal standard system, where it is normalised>.
ID decision: <which stable ID is the key>.

## 5. Write path (drop this section if the app only reads and sends nothing outside)

The same gates as `references/04-contracts-guardrails.md` section 2. Give a reason for any gate you drop.

| Gate | Present? | How |
|---|---|---|
| Validate + scope | | |
| Dry run by default | | |
| Preview for a person | | |
| Autonomy policy (automatic / needs approval / only a person decides) | | |
| Approval token bound to the payload | | |
| One transaction / one undo step | | |
| Read-back | | |
| Warnings returned as data | | |
| Log | | |
| Change cap | | |

Sending outside (reports, issues, email): <who approves, where it is logged>.
Origin label (`origin`) for values the app fills in: <where it is recorded>.

## 6. Measurement plan

| Check | Data | Metrics and acceptance threshold | When it runs |
|---|---|---|---|
| Deterministic checks (unit) | Planted-defect model: <description, number of planted defects> | | Every commit |
| Evals for the adaptive part | Gold set: <source, number of cases, who labels> | | Every change of prompt/model |
| Live run | <which real model, a copy> | | Before release |

Baselines to measure first: (a) the adaptive part switched off; (b) one LLM call.
Recorded on every run: <input, spec/code A produced, tools called, Findings, ChangeSet and approver, versions>.

## 7. Cost and models

| Adaptive sub-task | How it runs (chat / job / design-time) | Model class (small-fast / strong) | Calls per run | How to reduce (cache, batch, ratchet) |
|---|---|---|---|---|

Specific model names and prices: look them up in the provider's documentation at implementation time; do not hard-code them here.

Ratchet plan: <which A decisions will be lowered to a lookup table, tracked by which metric>.

## 8. Risks and unknowns

| Risk / assumption | Earliest check | What changes if it is wrong |
|---|---|---|

If the brief is too long, shorten in this order: section 7, section 6, section 8. Never shorten sections 2, 3, 4.

## 9. Next steps (at most 5)

1. <the smallest piece of work that proves the A/D boundary is right, usually: contracts + 20 gold cases + a planted-defect model>
