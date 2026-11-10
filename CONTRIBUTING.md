# Contributing

This repository is a set of Markdown files. There is nothing to build.

## What helps most

- **A counter-example.** A real case where a rule, a catalog row or a pattern gave the wrong advice. Say what you built, what the skill recommended, and what happened.
- **A missing task.** A common BIM task that is not in `references/03-task-catalog.md`. Propose the row: task, mode, how to split it, pattern.
- **A missed defect.** Something the review mode should have caught in your codebase and did not. Propose a checklist item for `references/06-anti-patterns.md`: the sign in the code, why it fails, the fix.
- **A source.** A public project or paper that supports or contradicts a claim in `references/07-field-notes.md`.

Open an issue first for anything larger than a few lines.

## Ground rules for changes

- Every recommendation needs a reason. No neutral "it depends" lists.
- Claims about other projects or benchmarks need a link, and the number must be in the linked source.
- No model names, prices or vendor recommendations.
- Keep the skill self-contained: no links to private repositories, no absolute paths.
- Keep `SKILL.md` short. Detail goes in `references/`, and `SKILL.md` says when to read each file.
- If you add or remove a pattern, a checklist code or a catalog section, update the counts in `README.md` and `SKILL.md`.

## Checking a change

There is no test suite. Before opening a pull request, run the skill once in the mode you changed, in a fresh session with no other context, and read the output as a first-time user would. Say in the pull request what you ran and what came back.
