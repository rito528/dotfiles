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

echo "==> Applying dotfiles..."
chezmoi init --source="$REPO_DIR"
chezmoi apply

echo "==> Applying home-manager configuration..."
"$REPO_DIR/install/common/home-manager.sh"

echo "==> Importing GPG keys..."
"$REPO_DIR/install/common/import_gpg.sh"

echo "==> Importing SSH keys..."
"$REPO_DIR/install/common/import_ssh_key.sh"

echo "Start Nix store gc to remove old keys..."
nix store gc

echo "Setup complete."
