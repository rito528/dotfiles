#!/bin/bash
# Install packages via home-manager
# Usage: ./install/common/home-manager.sh

set -euo pipefail

NIX_PROFILE=/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
if [ -e "$NIX_PROFILE" ] && ! command -v nix &>/dev/null; then
    # shellcheck source=/dev/null
    . "$NIX_PROFILE"
fi

FLAKE_PATH="$HOME/.config/home-manager"

if command -v home-manager &>/dev/null; then
    home-manager switch --flake "$FLAKE_PATH" --impure
else
    nix run nixpkgs#home-manager -- switch --flake "$FLAKE_PATH" --impure
fi
