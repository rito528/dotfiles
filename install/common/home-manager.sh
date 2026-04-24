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
        nix run --accept-flake-config nixpkgs#home-manager -- "$@"
    fi
}

switch_log="$(mktemp)"
trap 'rm -f "$switch_log"' EXIT

if run_home_manager switch --flake "$FLAKE_PATH#${FLAKE_USER}" >"$switch_log" 2>&1; then
    exit 0
fi

if grep -Eq "Existing file '.*' is in the way|Existing file '.*' would be clobbered" "$switch_log"; then
    echo "Existing unmanaged files detected. Retrying with backup extension '.backup'..." >&2
    run_home_manager switch --flake "$FLAKE_PATH#${FLAKE_USER}" -b backup
    exit 0
fi

cat "$switch_log" >&2
exit 1
