# Example output: Architecture Brief

This is a shortened brief produced by the skill in design mode. The request was:

> I want an app that lets engineers chat with a Revit model: ask about exit doors, check door widths against the fire code, and fill in missing Fire Rating values on walls. The model has about 80,000 elements, the check runs weekly, and the result goes to the client.

Nobody was available to answer questions, so the skill recorded its assumptions (marked **[A]**) and carried on. Clause numbers and thresholds are deliberately left out: the brief tells you where they must come from, it does not supply them.

Modes: **D** deterministic code · **A** adaptive AI · **H** hybrid · **Human**.

---

## Architecture Brief: Egress and Fire Rating assistant for Revit

- **One line:** Engineers ask questions about exit doors in plain language, the app checks door clear widths against the fire code and fills missing wall Fire Rating values; a weekly report goes to the client.
- **Maturity:** 0 (idea) to 3 (running on other people's models).

### 1. Context

| Item | Answer |
|---|---|
| Users | BIM and fire engineers who currently filter schedules and measure by hand **[A]** |
| Data | One Revit model, about 80,000 elements; the fire code as a PDF, edition to be fixed by the engineer |
| Writes | Yes: wall Fire Rating (a type parameter **[A]**), and a report sent outside the team |
| Accountability | An engineer signs before anything goes to the client **[A]** |
| Frequency | Weekly batch plus ad-hoc chat |

### 2. Task split

| # | Sub-task | Stage | Mode | Why | Output contract | How it is checked |
|---|---|---|---|---|---|---|
| 1 | Extract doors, walls, rooms and door-room relations; normalise to mm | Read | D | Computable; large volume | `Element[]` with stable IDs, unit, scope | Planted-defect model |
| 2 | List the categories and parameters that actually exist in this model | Read | D | Computable | `ModelSchema` | Unit tests |
| 3 | Understand a chat question | Interpret | A | Ambiguous input | `QuerySpec` with enums taken from #2, plus `needs_clarification` | Schema validation; gold set |
| 4 | Run the QuerySpec | Read | D | Computable; large volume | Count, sample, pages | Unit tests |
| 5 | Draft the door-width rule from the code text (once, at design time) | Design-time | H | Verdict must be repeatable; source is prose | Rule pack entry with citation, unit, pass and fail examples | Example-based tests; engineer approves |
| 6 | Declare occupancy and occupant load, which select the threshold | Decide | Human | Cannot be verified by machine | `ProjectParams` | Missing means `missing_data` |
| 7 | Decide which doors are exit doors | Judge | D | Verdict must be repeatable | Declared parameter cross-checked against the room-door graph; disagreement means `manual_review` | Planted-defect model |
| 8 | Measure clear width and compare to the threshold | Judge | D | Computable; repeatable | `Finding` with four statuses | Planted defects, including near-threshold and missing-data cases |
| 9 | Map wall type to Fire Rating | Decide | H | Long tail of type names; life-safety | Versioned lookup table with `origin`; AI only suggests for unmatched types; engineer approves every value | Gold set, two labellers |
| 10 | Build the change set and write it | Write | D behind a gate | Writes to the model | `ChangeSet` with fingerprint, type vs instance, affected instance count | Read-back |
| 11 | Weekly report | Present | D | Fixed template | Rendered from `Finding` | Every number traces to a Finding |
| 12 | Chat answer | Present | A | Language | Prose plus IDs issued by code | Numbers in the text compared with the source |
| 13 | Sign and send to the client | Write | Human | Leaves the team | Log entry | n/a |

Seven D, two A, two H, two Human.

### 3. Flow

```
CHAT
 question -> (A interpret) -QuerySpec-> [D validate + query] -compact result-> (A answer)
                 ^ ModelSchema [D]

WEEKLY (no LLM on the verdict path)
 [D adapter] -Element[]-> [D engine + rule pack] -Finding[]-> [D render report] -> <> engineer signs -> client
                               | walls with no Fire Rating
                               v
        [D lookup type->rating] -no match-> (A suggests) -> <> engineer approves -> lookup v+1
               '-ChangeSet (dry run)-> <> approve, token bound to fingerprint
                        -> [D one transaction] -> [D read-back] -> [log]

DESIGN TIME
 fire code text -> (A drafts rule with citation) -> <> engineer approves + tests -> versioned rule pack
```

`[ ]` code · `( )` AI · `<>` a person approves.

Patterns used: interpret-then-execute (chat), offline rule authoring (rule pack), rules-first with AI for the remainder (Fire Rating lookup), verdict-by-code with words-by-AI (report), write gate.
Shape of the AI part: a fixed workflow with two calls per chat question. No agent: the steps are known in advance.

### 4. Write path

- Dry run by default. The weekly job produces a change set and a preview; it never writes on its own.
- The preview is a before/after table per wall type with the number of instances affected.
- Fire Rating is life-safety, so a person decides every value. A value suggested by the AI reaches the model only through the approved lookup table.
- One transaction, read-back, software warnings returned as data, append-only log, a cap on types changed per batch.

### 5. Measurement

- **Deterministic checks:** a model with about 30 planted defects (narrow doors, near-threshold doors, missing rooms, walls without a rating). Report recall and precision.
- **AI evaluation:** 20 to 50 real questions from engineers; real wall type names labelled by two people.
- **Live run:** a copy of a project model.
- **Baseline first:** the same app with the AI switched off (a filter form instead of chat; lookup table only).

### 6. Risks

| Risk or assumption | Earliest check | If wrong |
|---|---|---|
| The model lacks rooms or door-room relations | Run sub-task 1 on a copy | Most results become `missing_data`; fix the model first |
| The source of truth for Fire Rating is unclear (fire strategy documents, or inferred from type names?) | Ask the fire engineer | Drop the AI from sub-task 9; import a table made by a person |
| "Chat with Revit" may already exist as a general agent plus an MCP server | Try it for a week with an existing adapter | Skip the chat layer; put the effort into the engine and the rule pack |
| Values the app filled in later feed the verdicts | Record `origin` on every filled value | Split the report by origin |

### 7. Next steps

1. Schemas for QuerySpec and Finding, 20 gold questions, a model with 30 planted defects.
2. The door-width rule: AI drafts, engineer approves, example tests pass.
3. Run sub-tasks 7 and 8 on a copy of the 80,000-element model; count `missing_data`.
4. Fire Rating lookup v0 made by the engineer; the write gate in dry-run mode.
5. Render the report from Findings; have the engineer sign a trial week.
