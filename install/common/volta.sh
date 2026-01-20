#!/bin/bash
# Install Volta (JavaScript toolchain manager)
# Usage: ./install/common/volta.sh

set -euo pipefail

if command -v volta &>/dev/null; then
    echo "Volta is already installed"
    exit 0
fi

echo "Installing Volta..."
curl https://get.volta.sh | bash

echo "Volta installation complete."
echo "Please restart your shell or run: export VOLTA_HOME=\"\$HOME/.volta\" && export PATH=\"\$VOLTA_HOME/bin:\$PATH\""
