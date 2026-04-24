#!/bin/bash
# Install packages via home-manager
# Usage: ./install/common/home-manager.sh

set -euo pipefail

if [ "${EUID:-$(id -u)}" -eq 0 ]; then
    echo "Error: Do not run this script as root or with sudo." >&2
    exit 1
fi

NIX_PROFILE=/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
if [ -e "$NIX_PROFILE" ] && ! command -v nix &>/dev/null; then
    # shellcheck source=/dev/null
    . "$NIX_PROFILE"
fi

NIX_USER_CONF="${XDG_CONFIG_HOME:-$HOME/.config}/nix/nix.conf"
if ! grep -qE '^accept-flake-config\s*=' "$NIX_USER_CONF" 2>/dev/null; then
    mkdir -p "$(dirname "$NIX_USER_CONF")"
    echo "accept-flake-config = true" >> "$NIX_USER_CONF"
    echo "Set accept-flake-config = true in $NIX_USER_CONF" >&2
fi

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FLAKE_PATH="$REPO_DIR"
FLAKE_USER="${HM_FLAKE_USER:-${USER}}"

run_home_manager() {
    if command -v home-manager &>/dev/null; then
        home-manager "$@"
    else
        nix run nixpkgs#home-manager -- "$@"
    fi
}

run_home_manager switch --flake "$FLAKE_PATH#${FLAKE_USER}"
