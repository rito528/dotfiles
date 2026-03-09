#!/bin/bash
# Dotfiles setup script
# Usage: ./setup.sh

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Installing packages..."
"$REPO_DIR/install/ubuntu/packages.sh"

echo "==> Installing chezmoi..."
"$REPO_DIR/install/common/chezmoi.sh"

echo "==> Applying dotfiles..."
chezmoi init --source="$REPO_DIR"
chezmoi apply

echo "Setup complete."
