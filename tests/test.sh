#!/bin/bash
# Run integration tests for dotfiles
# Usage: ./tests/test.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

echo "Building test Docker image..."
docker build -t dotfiles-test -f "$SCRIPT_DIR/Dockerfile" "$REPO_ROOT"

echo "Test passed: home-manager switch succeeded"
