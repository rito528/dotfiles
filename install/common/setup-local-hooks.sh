#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

current="$(git -C "$REPO_DIR" config --local core.hooksPath 2>/dev/null || true)"

if [ "$current" = ".githooks" ]; then
  echo "core.hooksPath is already set to .githooks. Skipping."
  exit 0
fi

git -C "$REPO_DIR" config --local core.hooksPath .githooks
echo "core.hooksPath set to .githooks."
