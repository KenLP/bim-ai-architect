# bim-ai-architect

**A decision framework for building AI applications in BIM/AEC: which parts should be deterministic code, which parts should be an LLM, and how to join the two safely.**

It ships as a [Claude Code](https://claude.com/claude-code) skill, and every file is plain Markdown you can read without any tool.

## The problem

Most BIM AI apps fail for the same reason: the wrong kind of worker gets the job. A language model is asked to add up areas, decide pass/fail against a code clause, or write straight into the model. It is fluent, it is usually close, and when it is wrong the answer still looks right.

The fix is rarely "use a better model". It is to split the app into small tasks and give each one to the right worker:

| Worker | Good at | Bad at |
|---|---|---|
| **Deterministic code** (rule engine, geometry kernel, compiler, validator) | Counting, measuring, thresholds, writing to the model. Same input, same output | Anything phrased loosely |
| **Adaptive AI** (LLM, VLM, agent) | Natural language, regulation text, messy naming, drawings, prose | Arithmetic, geometry, repeatable verdicts |
| **A person** | Approving, signing, deciding what is acceptable | Doing it 80,000 times |

This skill walks you through that split and hands back a design you can build from.

## What you get

| You type | You get |
|---|---|
| `/bim-ai-architect <your app idea>` | An **Architecture Brief**: every sub-task assigned to code, AI or a person, with the reason; a flow diagram; the contracts between the parts; the write gate; an evaluation plan; a cost estimate |
| `/bim-ai-architect review` | A **review** of an existing app against a 53-item anti-pattern checklist, with `file:line` evidence and the three changes that matter most |
| A plain question, e.g. "should clash prioritisation use an LLM?" | A **short answer**: the mode, how to split the work, why, and the trap to avoid |

The skill is written in English and replies in whatever language you write in.

## Quick start

**Claude Code, as a plugin** (two commands inside a session):

```
/plugin marketplace add KenLP/bim-ai-architect
/plugin install bim-ai-architect@bim-ai-kit
```

**Claude Code, as a plain skill** (no plugin system):

```bash
git clone --depth 1 https://github.com/KenLP/bim-ai-architect
```

```bash
./bim-ai-architect/install.sh
```

On Windows PowerShell, run `.\bim-ai-architect\install.ps1` instead of the second command.

Then start a new session and describe the app you want to build. Other ways to install (project scope, claude.ai upload, other coding agents) are in [docs/INSTALL.md](docs/INSTALL.md).

## The idea in one minute

**Adaptive AI at the edges, deterministic code at the core, joined by contracts you can check.**

Break the app along six stages, then decide each sub-task separately:

| Stage | Question it answers | Default |
|---|---|---|
| Read | What is in the model, the CDE, the documents? | Code |
| Interpret | What does the user or the text mean? | AI |
| Judge | Does it comply? How much? Where? | Code |
| Decide | What do we do about it? | Policy table in code, AI proposes |
| Write | Change the model or the CDE | Code, behind an approval gate |
| Present | Explain, report, draft | AI writes the words over numbers from code |

Ten rules hold the design together:

1. **Numbers come from tools, not from the model.**
2. **Verdicts must be repeatable.** A rule engine decides pass/fail; the AI explains.
3. **The AI never holds the pen.** It proposes a change set; code writes it through a gate (validate, preview, approve, one transaction, read back, log).
4. **The AI stops where structure begins.** Its output is schema-checked data with closed enums. Bad output is rejected, never coerced.
5. **The AI writes once, code runs N times.** No LLM call per element; no dumping the model into context.
6. **IDs and coordinates are issued by code.**
7. **Four outcomes, not two:** compliant, non-compliant, needs a person, data missing. Silence is not a pass.
8. **Rules are data, kept in one place.** Not in prompts, not in adapters.
9. **No evaluation, no prompt or model change.**
10. **Use the lowest rung that works, and keep lowering it.** One call before an agent; a decision the AI keeps making the same way becomes a lookup table.

## What's inside

All under [`plugins/bim-ai-architect/skills/bim-ai-architect/`](plugins/bim-ai-architect/skills/bim-ai-architect/):

| File | What it is |
|---|---|
| `SKILL.md` | Entry point: the three modes, the six-step design procedure, the ten rules |
| `references/01-rubric.md` | Six stages, seven questions, a two-axis matrix, the architecture ladder |
| `references/02-patterns.md` | Ten ways to combine code and AI (interpret-then-execute, compiler, rules-first with AI for the remainder, propose-check-choose, write gate, and more) |
| `references/03-task-catalog.md` | About 45 common BIM tasks, each with a recommended mode and pattern |
| `references/04-contracts-guardrails.md` | The five contracts, the write gate, BIM-specific traps (units, IDs, type vs instance, model size), rules for bolting an LLM onto a deterministic core |
| `references/05-evals-cost.md` | Planted-defect models, gold sets, live runs, metrics, cost levers, a maturity ladder |
| `references/06-anti-patterns.md` | 53 coded anti-patterns with severity, plus five path traces to run during a review |
| `references/07-field-notes.md` | The evidence: lessons from production BIM AI systems, open-source projects worth reading, and where LLMs fail on BIM data according to public benchmarks |
| `assets/ARCHITECTURE_BRIEF.template.md` | The output template |

A worked example of the output is in [docs/EXAMPLE_BRIEF.md](docs/EXAMPLE_BRIEF.md).

## How it was tested

Three runs so far, each by a fresh agent with no prior context:

- **Design, generic app.** A chat-with-Revit egress checker. The agent produced a complete brief and reported about 25 unclear or inconsistent instructions, which were then fixed.
- **Review, blind.** An older snapshot of a production audit tool for which an independent review had already listed 19 defects in its LLM layer. The agent did not see that list. It recovered 4 of the 6 high-severity defects and 9 of the 19 overall. The misses led to 13 new checklist items and the five path traces.
- **Design, real project.** Adding an LLM planner to an existing townhouse compiler. The brief was judged usable by the project owner, and it pushed back on the request: it kept layout generation in code and limited the LLM to understanding the client's words.

What this does **not** show: the fixes made after each run have not been re-scored on a fresh codebase, and nobody outside the author's team has used the skill yet.

## Limits

- It is a design aid. It does not write your app, and its recommendations are opinions with reasons, not standards.
- The task catalog and patterns come from Revit, IFC and ACC work. Other platforms should map across, but that is untested.
- Benchmark figures quoted in the field notes were read from the cited sources in November 2026. Check the source before you quote them.
- No model names or prices are recommended. Those change too often; look them up when you build.

## Contributing

Corrections, counter-examples and new catalog rows are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

[MIT](LICENSE)
