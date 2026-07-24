#!/usr/bin/env bash
set -euo pipefail

# home-manager によって配備先で相対パスが変わるため、リンクチェックの対象外とする。
IGNORE_PATHS="config/agents/skills/,config/agents/AGENTS.md,config/claude/CLAUDE.md"

if [[ $# -eq 0 ]]; then
  exit 0
fi

markdown-link-check -i "$IGNORE_PATHS" "$@"
