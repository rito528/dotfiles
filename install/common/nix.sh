#!/bin/bash
# Install Nix package manager
# Usage: ./install/common/nix.sh

set -euo pipefail

if command -v nix &>/dev/null; then
    echo "Nix is already installed"
    exit 0
fi

echo "Installing Nix (Determinate Systems installer)..."
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix \
    | sh -s -- install --no-confirm

echo "Nix installation complete."
echo "Please restart your shell or run: . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
