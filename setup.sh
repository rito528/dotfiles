#!/bin/bash
# Dotfiles setup script
# Usage: ./setup.sh

# sh で実行された場合は bash で再実行する
if [ -z "${BASH_VERSION:-}" ]; then
    exec bash "$0" "$@"
fi

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Installing packages..."
"$REPO_DIR/install/ubuntu/packages.sh"

echo "==> Installing Nix..."
"$REPO_DIR/install/common/nix.sh"

echo "==> Installing chezmoi..."
"$REPO_DIR/install/common/chezmoi.sh"

echo "==> Installing secretlint..."
bash "$(dirname "$0")/install/common/secretlint.sh"

echo "==> Applying dotfiles..."
chezmoi init --source="$REPO_DIR"
chezmoi apply

echo "Setup complete."
