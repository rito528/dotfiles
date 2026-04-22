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
        nix run nixpkgs#home-manager -- "$@"
    fi
}

maybe_migrate_nvim_layout() {
    local nvim_dir target

    nvim_dir="${HOME}/.config/nvim"
    if [ ! -L "$nvim_dir" ]; then
        return 0
    fi

    target="$(readlink -f "$nvim_dir" || true)"
    case "$target" in
        /nix/store/*)
            echo "Migrating existing Neovim symlink to directory-based Home Manager layout..." >&2
            rm "$nvim_dir"
            ;;
    esac
}

switch_log="$(mktemp)"
trap 'rm -f "$switch_log"' EXIT

if run_home_manager switch --flake "$FLAKE_PATH#${FLAKE_USER}" >"$switch_log" 2>&1; then
    exit 0
fi

if grep -Eq "Existing file '.*' is in the way|Existing file '.*' would be clobbered" "$switch_log"; then
    if grep -Eq "Existing file '${HOME//\//\\/}/\\.config/nvim/.*' is in the way|Existing file '${HOME//\//\\/}/\\.config/nvim/.*' would be clobbered" "$switch_log"; then
        maybe_migrate_nvim_layout
    fi
    echo "Existing unmanaged files detected. Retrying with backup extension '.backup'..." >&2
    run_home_manager switch --flake "$FLAKE_PATH#${FLAKE_USER}" -b backup
    exit 0
fi

cat "$switch_log" >&2
exit 1
