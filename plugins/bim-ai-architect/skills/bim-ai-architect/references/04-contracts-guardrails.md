# 04 - Seams (contracts), the write gate, and BIM-specific traps

The place where A meets D is where apps break most often. Design the seam first, write the prompt afterwards.

## 1. Five contracts you should have

### 1.1 Intent / QuerySpec (A → D, Interpret stage)
- JSON against a schema, produced with structured output or a tool call; validated before use.
- **Closed enums** for what the model already knows: category, parameter name, level, phase, operator. Take the lists from the real model and put them in the schema or the prompt; do not let A guess names.
- The unit is a separate field (`{value: 900, unit: "mm"}`), not part of a string.
- An exit route: `needs_clarification`, `unsupported`. A is allowed to say "not enough information".
- Structured output guarantees *shape*, not *values*. Min/max ranges, string lengths, cross-references, whether an ID exists: all must be validated in code. Bad output is **rejected**, never coerced into passing.
- **Anchor with quotes.** When A extracts information from speech or text, every value carries the verbatim quote; D checks that the quote is a substring of the input. This catches invented values, not misreadings; misreadings need a person to confirm and a gold set.
- **Outcomes of the Interpret and generation stages** are not the four Finding statuses. Use a separate set: `ready` · `needs_clarification` (required information missing) · `unsupported` (outside what the system can do, with a reason from an enum) · `infeasible` (in scope but no valid solution exists). Values the system filled in itself carry `origin: default`.

### 1.2 Intermediate spec (A → compiler, Write stage for many elements)
- Carries domain meaning (rooms, grids, levels, adjacency/connection), not API calls.
- Keep the intent spec (A may write it) apart from the geometric spec with coordinates (only D writes it); see pattern P2.
- Can be validated independently of the authoring software: geometric constraints, cross-references, valid values.
- Versioned. Same spec + same compiler → same model.

### 1.3 Rule pack (Human + A author → D runs, Judge stage)
Each rule has at least: a stable `id` · a source citation (document, article, clause) · scope · the measured quantity and its **unit** · threshold · severity · whether it can be auto-fixed · passing and failing examples (used as tests).
- Rules are data (YAML/JSON), not in prompts, not in adapters.
- Two separate layers: *source text with citations* and *executable rules*. A threshold changes in one place.

### 1.4 Finding (D → everywhere, Judge → Present)
One verdict record shared by every checker. The example below only illustrates the shape; the rule ID and the numbers are made up, not taken from any standard:

```json
{
  "rule_id": "EXAMPLE.DOOR.MIN_CLEAR_WIDTH",
  "element_id": "<stable id, see section 3>",
  "status": "non_compliant",
  "severity": "high",
  "measured": {"value": 780, "unit": "mm"},
  "required": {"op": ">=", "value": 900, "unit": "mm"},
  "evidence": {"tool": "geometry.door_clear_width", "tool_version": "1.4.2", "model_version": "…"},
  "suggested_fix": null
}
```
- **Four statuses, not two:** `compliant` · `non_compliant` · `manual_review` (ambiguous criterion, needs a person) · `missing_data` (not enough data to check). Silence is not a pass.
- The status of the *run* (completed, failed, no response) is a different thing and is recorded separately. A tool timeout or an adapter that does not answer → the affected elements get `missing_data` with a reason, and the run is recorded as incomplete.
- A reads Findings to write words; A neither creates nor edits Findings.

### 1.5 ChangeSet (A proposes → write gate)
- A list of changes as data: which element, which parameter, from what value to what value, because of which Finding.
- Has a fingerprint. The approval token is bound to the fingerprint; change the content and it must be approved again.
- Every value carries `origin`: `rule` (lookup table/formula), `llm` (A proposed it), `human` (a person entered it). Values written to the model keep this label (in a side parameter or the log), because they may come back as inputs to a verdict; reports sent outside separate results that rely on values the app filled in itself.

## 2. The write gate: fixed order

```
validate payload → check scope/permissions → preview (dry run by default) → approve (person or policy)
   → execute in ONE transaction → read-back → append-only log → return warnings as data
```

| Gate | Rule | Reason |
|---|---|---|
| Validate + scope | The payload matches the schema; elements, project and change type are within the allowed scope | Stops invented payloads before they reach the software |
| Dry run by default | Writing for real needs an explicit flag | A wrong default must fail safe |
| Preview | Show the person *what will change* (before/after table, colours in a view, number of instances affected) | People approve what they can see |
| Autonomy policy | A D table: severity × change type → automatic / needs approval / only a person decides | Do not let A decide its own level of autonomy |
| Approval token | Bound to the payload hash, single use, with an expiry | Once approved, the content cannot be changed |
| One transaction | The whole batch is one undo step | The user reverts with one Ctrl+Z; a failure halfway does not leave the model half-changed |
| Read-back | After writing, read back and compare with the ChangeSet | An API that returns OK does not guarantee the value went in (read-only parameter, type vs instance, pushed back by a constraint) |
| Warnings as data | Software warnings returned to the caller with element IDs; errors cause a rollback | Modal dialogs hang unattended runs; swallowed warnings are hidden defects |
| Log | Append-only: who, approved what, which payload, what result | Explaining it later |
| Change cap | A cap on changes per run / per minute | Stops a runaway agent loop |

Sending results outside (email, issue, a report for a third party) is also a write: there is no transaction and no undo, so the minimum gate is preview, an approver and a log.

**Building from scratch** (a compiler creating a model in a new file) reads the table above by analogy: there is no "before/after", so the preview is a drawing of the spec (floor plans, a draft 3D view); what gets approved is the locked spec with its hash; instead of one transaction, build into a fresh copy of the seed file, never retry midway, and leave a failed run in its failed state; the read-back compares the model with the spec.

Operating rule while experimenting: use a copy or a test model; when you open a real model, do not edit it and close it without saving.

## 3. BIM-specific traps (put them on the design checklist)

**Units.** Revit stores feet internally; IFC declares its units in the file and they can differ between files; users say mm or m. Convention: normalise to one system right at the adapter, every contract carries a `unit` field, and A never converts units itself.

**Identifiers.** Revit's ElementId can change; UniqueId and IFC GlobalId are more stable but still change when an element is recreated or re-exported badly. Pick one stable ID as the key in Findings and ChangeSets. A may only *choose* IDs from a list D provides.

**Type and instance.** The same parameter name can live on the type or on the instance. Editing the type edits every instance. A ChangeSet must say which one it changes; the preview must count the affected instances. An empty string is not the same as no value.

**Hidden model state.** Phases, design options, worksets, links, the active view, hidden elements. A query for "all walls" gives different answers depending on these. The query contract must state its scope explicitly, and the result must return the scope that was used.

**Model size.** A real model has 10⁴-10⁶ elements, each with dozens of parameters. Never put raw data in the context. Tools must count and group on the server side, select fields, paginate, and return a sample + totals. For analytical questions use P10.

**Geometry.** LLMs reason poorly and inconsistently about space. Every measurement, intersection, containment and path goes through a kernel. Tolerance is a rule parameter, not a gut feeling.

**Local naming.** Category, family and parameter names depend on the UI language, company templates and project habits. Use internal IDs/enums as keys (for example BuiltInCategory, IFC entity) and display names only for presentation. Mapping tables are versioned data (P5).

**Software with a UI.** Modal dialogs, models that need upgrading, unsigned add-ins, one process per version. Unattended runs need a policy for answering dialogs and must record the dialogs they met.

**Versions.** The API differs between release years; IFC2x3 and IFC4 schemas differ. The adapter hides the differences; the contracts above it do not change.

**IFC export loses information.** The export settings decide what is present. Data missing from the IFC must give `missing_data`, not `non_compliant`.

## 4. Layer boundaries (keep the app from tangling as it grows)

```
Channel (web, chat, add-in)
Product (business flow, policy, reports)
Core (verdict engine, compiler, solver)       ← receives extracted data, does NOT call the authoring software/CDE directly
Adapter (Revit, IFC, ACC/APS, Speckle…)       ← does NOT contain standards or verdict logic
Outside world
```
- Data flows up, actions flow down. The product reads through the adapter, calls the core to judge, and writes back through a gated adapter.
- Rules live in one place (the rule pack). Adapters and UIs only *serve* the rules.
- A may sit in the Product and Channel layers. The Core and Adapter layers are D.

## 5. Rules for an add-on AI layer on a deterministic core

These apply whenever A proposes values or actions to a deterministic core, whether the core already existed or is being designed at the same time (fix suggestions, diagnosis, orchestration):

1. **It can be switched off with a flag.** With the A layer off, the D core runs and gives exactly the same result as before A existed. This is also the baseline for measuring whether A is worth its cost.
2. **A proposes; the same rule that detected the problem re-checks it.** A proposal that fails the rule is not applied and goes to a person.
3. **An "advisory only" role must be enforced by the core, not just written in the docs.** An advisory A has no path to write to the Finding list, statuses or coverage. Test it: have a fake A return destructive data; the core must ignore it.
4. **A's failures must not break D's work.** Timeouts, network errors, wrong-schema output in the A layer → record, skip, continue. Above all after the model has already been written to.
5. **Autonomy is computed from the rule, never taken from A.** Values A produced (`origin: llm`) are never applied automatically. Life-safety items are "a person decides": a person chooses each value; the system may still write them in bulk after approval, and A's suggestions reach the model only through a lookup table a person has approved.
6. **Fallback behind the same interface, and say who ran.** When A fails → fall back to the rule/keyword version behind the same interface; the result records `origin` (rule or llm) so users and whoever debugs it know.
7. **No path bypasses the validator.** Cache, memo, batch calls and fallbacks all return values through the same validator; the cache key includes every input the validator uses. Batch answers must carry IDs and be matched against the elements that were asked about.
8. **The validator must mean something.** A rule that only checks form ("not empty", correct format) does not prove a value is right. Limit which kinds of rules accept proposals from A, check type and size in the core, and leave the rest to a person.
9. **Switches fail safe.** An unknown model provider name stops the run instead of falling back to the cloud. A mistyped flag for enabling A raises a warning instead of silently running without A. The run record says whether A took part.

Also check: an A layer or plugin released separately needs its own compatibility tests. A green core test suite says nothing about the A layer.

## 6. Designing tools for an agent (when using P7)

- Few tools, named after what the user wants to do, not after API function names. Group them into a profile per role.
- Tool descriptions say clearly: when to use it, when not to, units, default scope, result size.
- Results are compact and structured; errors have a code and a suggested next step.
- Read tools and write tools are kept apart; write tools always have a dry-run parameter.
- Keep stable what clients depend on: tool names, result shapes, error codes. Changing them breaks clients, even when your own tests stay green.
