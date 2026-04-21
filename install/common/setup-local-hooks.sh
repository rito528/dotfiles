#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# This repository uses repo-local hooks in .githooks/.
# Do not rely on a global hooksPath for repo-specific checks.
current="$(git -C "$REPO_DIR" config --local core.hooksPath 2>/dev/null || true)"

if [ "$current" = ".githooks" ]; then
  echo "Repo-local git hooks are already enabled (.githooks). Skipping."
  exit 0
fi

git -C "$REPO_DIR" config --local core.hooksPath .githooks
echo "Enabled repo-local git hooks from .githooks."
