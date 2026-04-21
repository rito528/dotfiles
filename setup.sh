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

echo "==> Installing Docker..."
"$REPO_DIR/install/ubuntu/docker.sh"

echo "==> Installing CA certificate..."
"$REPO_DIR/install/common/ca-certs.sh"

echo "==> Installing Nix..."
"$REPO_DIR/install/common/nix.sh"

echo "==> Applying home-manager configuration..."
"$REPO_DIR/install/common/home-manager.sh"

echo "==> Configuring login shell (zsh)..."
"$REPO_DIR/install/common/chsh-zsh.sh"

echo "==> Enabling repo-local git hooks..."
"$REPO_DIR/install/common/setup-local-hooks.sh"

echo "Setup complete."
