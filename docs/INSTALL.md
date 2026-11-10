# Installing bim-ai-architect

Pick one route. All of them install the same files.

| Route | Best for | Updates |
|---|---|---|
| [A. Plugin](#a-claude-code-plugin) | Claude Code users | `/plugin marketplace update` |
| [B. Install script](#b-install-script) | Claude Code without the plugin system | Re-run the script |
| [C. Manual copy](#c-manual-copy) | One project only, or a locked-down machine | Copy again |
| [D. Other agents and chat apps](#d-other-agents-and-chat-apps) | Anything that can read Markdown | Pull the repo |

## A. Claude Code plugin

Inside a Claude Code session:

```
/plugin marketplace add KenLP/bim-ai-architect
/plugin install bim-ai-architect@bim-ai-kit
```

The same from a shell:

```bash
claude plugin marketplace add KenLP/bim-ai-architect
```

```bash
claude plugin install bim-ai-architect@bim-ai-kit
```

Start a new session. The skill is available as `/bim-ai-architect:bim-ai-architect`, and Claude also loads it on its own when you describe a BIM AI app you want to build.

To update later:

```bash
claude plugin marketplace update bim-ai-kit
```

To remove:

```bash
claude plugin uninstall bim-ai-architect@bim-ai-kit
```

## B. Install script

Clone, then run the script for your shell. It copies the skill folder into your user-level skills directory (`~/.claude/skills/bim-ai-architect`).

```bash
git clone --depth 1 https://github.com/KenLP/bim-ai-architect
```

macOS, Linux, Git Bash:

```bash
./bim-ai-architect/install.sh
```

Windows PowerShell:

```powershell
.\bim-ai-architect\install.ps1
```

Both scripts accept a project flag that installs into the current project instead (`./.claude/skills/`), so the skill travels with the repository:

```bash
./bim-ai-architect/install.sh --project
```

```powershell
.\bim-ai-architect\install.ps1 -Project
```

The scripts overwrite an existing copy of this skill and touch nothing else. To update, `git pull` in the clone and run the script again. To remove, delete the `bim-ai-architect` folder from the skills directory.

Installed this way the skill is invoked as `/bim-ai-architect`.

## C. Manual copy

Copy this folder:

```
plugins/bim-ai-architect/skills/bim-ai-architect/
```

to one of:

| Scope | Destination |
|---|---|
| Every project on this machine | `~/.claude/skills/bim-ai-architect/` (Windows: `%USERPROFILE%\.claude\skills\bim-ai-architect\`) |
| One project | `<project>/.claude/skills/bim-ai-architect/` |

The folder must keep its structure: `SKILL.md` at the top, with `references/` and `assets/` beside it.

## D. Other agents and chat apps

The skill is ordinary Markdown with no scripts, so it works anywhere an assistant can read files.

- **Agents that read a repository** (Cursor, Codex, Gemini CLI and similar): clone this repo next to your project, or copy the skill folder in, and say: *"Read `SKILL.md` in the bim-ai-architect folder and follow it for this request: ..."*
- **Chat apps that accept uploaded skills or files:** download `bim-ai-architect.zip` from the [latest release](https://github.com/KenLP/bim-ai-architect/releases/latest) and upload it where the app lets you add a skill. If the app only takes plain files, upload `SKILL.md` together with the files under `references/`.
- **No assistant at all:** start with `references/01-rubric.md` and `references/03-task-catalog.md`. They read as a short handbook.

## Check that it works

In a new session, ask:

> Should clash prioritisation use an LLM?

A working install answers in a few lines with a mode (hybrid), how to split the work, a reason, and a trap to avoid. If the assistant answers generically without mentioning the task catalog or a pattern, the skill was not loaded: check the destination path and that `SKILL.md` sits directly inside the `bim-ai-architect` folder.

## Requirements

None beyond the assistant itself. No API keys, no network access, no code execution.
