#!/usr/bin/env bash
# Install the bim-ai-architect skill for Claude Code.
#   ./install.sh            -> ~/.claude/skills/bim-ai-architect   (every project)
#   ./install.sh --project  -> ./.claude/skills/bim-ai-architect   (current directory only)
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
SRC="$HERE/plugins/bim-ai-architect/skills/bim-ai-architect"

if [ ! -f "$SRC/SKILL.md" ]; then
  echo "error: skill not found at $SRC" >&2
  exit 1
fi

if [ "${1:-}" = "--project" ]; then
  DST_ROOT="$(pwd)/.claude/skills"
else
  DST_ROOT="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills"
fi
DST="$DST_ROOT/bim-ai-architect"

mkdir -p "$DST"
cp -R "$SRC/." "$DST/"

echo "Installed bim-ai-architect to $DST"
echo "Start a new Claude Code session and type /bim-ai-architect, or just describe the BIM AI app you want to build."
