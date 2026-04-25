#!/bin/bash
# Install packages via home-manager
# Usage: ./install/common/home-manager.sh

set -euo pipefail

NIX_PROFILE=/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
if [ -e "$NIX_PROFILE" ] && ! command -v nix &>/dev/null; then
    # shellcheck source=/dev/null
    . "$NIX_PROFILE"
fi

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FLAKE_PATH="$REPO_DIR"
FLAKE_USER="${HM_FLAKE_USER:-${USER}}"

run_home_manager() {
    if command -v home-manager &>/dev/null; then
        home-manager "$@"
    else
        nix --option accept-flake-config true run nixpkgs#home-manager -- "$@"
    fi
}

run_home_manager --option accept-flake-config true switch --flake "$FLAKE_PATH#${FLAKE_USER}"
