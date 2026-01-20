#!/bin/bash
# Install Ubuntu/Debian packages
# Usage: ./install/ubuntu/packages.sh

set -euo pipefail

PACKAGES=(
    git
    curl
    wget
    gpg
    jq
    direnv
    build-essential
)

echo "Updating package list..."
sudo apt-get update

echo "Installing packages..."
for pkg in "${PACKAGES[@]}"; do
    if dpkg -l "$pkg" &>/dev/null; then
        echo "$pkg is already installed"
    else
        echo "Installing $pkg..."
        sudo apt-get install -y "$pkg"
    fi
done

echo "Ubuntu packages installation complete."
