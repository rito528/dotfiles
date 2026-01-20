#!/bin/bash
# Install chezmoi
# Usage: ./install/common/chezmoi.sh

set -euo pipefail

if command -v chezmoi &>/dev/null; then
    echo "chezmoi is already installed"
    exit 0
fi

echo "Installing chezmoi..."
sh -c "$(curl -fsLS get.chezmoi.io)"

echo "chezmoi installation complete."
