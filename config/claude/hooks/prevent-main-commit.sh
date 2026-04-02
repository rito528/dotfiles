#!/usr/bin/env bash
set -euo pipefail

input=$(cat)
command=$(echo "$input" | jq -r '.tool_input.command // empty')

if [[ "$command" != *"git commit"* ]]; then
  exit 0
fi

branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
[[ -z "$branch" ]] && exit 0

# Determine default branch from remote; fallback to main/master
default_branch=$(git remote show origin 2>/dev/null | grep 'HEAD branch' | awk '{print $NF}')
if [[ -z "$default_branch" ]]; then
  if [[ "$branch" == "main" || "$branch" == "master" ]]; then
    default_branch="$branch"
  fi
fi

if [[ -n "$default_branch" && "$branch" == "$default_branch" ]]; then
  echo "ERROR: Committing directly to '$branch' branch is not allowed." >&2
  echo "Please create a feature branch first: git switch -c <branch-name>" >&2
  exit 2
fi
