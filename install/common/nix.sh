#!/bin/bash
# Install Nix package manager
# Usage: ./install/common/nix.sh

set -euo pipefail

NUMTIDE_SUBSTITUTER="https://cache.numtide.com"
NUMTIDE_PUBLIC_KEY="niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
CACHIX_SUBSTITUTER="https://rito528-dotfiles.cachix.org"
CACHIX_PUBLIC_KEY="rito528-dotfiles.cachix.org-1:Kp/hDIx4sR31gHfT0z0D1RxjdpSrh47nHqzOtDXL/mE="

# extra-trusted-substituters はシステム nix.conf に書く必要がある。
# flake.nix の nixConfig による extra-substituters は trusted user でないと無視されるため。
configure_nix_caches() {
    local nix_conf="/etc/nix/nix.conf"
    local nix_custom_conf="/etc/nix/nix.custom.conf"
    local target_conf="$nix_conf"
    local restart_required=0

    if grep -q '^!include nix\.custom\.conf$' "$nix_conf" 2>/dev/null; then
        target_conf="$nix_custom_conf"
        sudo touch "$target_conf"
    fi

    for substituter in "$NUMTIDE_SUBSTITUTER" "$CACHIX_SUBSTITUTER"; do
        if grep -qF "$substituter" "$target_conf" 2>/dev/null; then
            echo "Cache substituter $substituter is already configured in $target_conf"
        else
            echo "Configuring cache substituter $substituter in $target_conf..."
            echo "extra-trusted-substituters = $substituter" | sudo tee -a "$target_conf" > /dev/null
            restart_required=1
        fi
    done

    for key in "$NUMTIDE_PUBLIC_KEY" "$CACHIX_PUBLIC_KEY"; do
        if grep -qF "$key" "$target_conf" 2>/dev/null; then
            echo "Cache public key is already configured in $target_conf"
        else
            echo "Configuring cache public key in $target_conf..."
            echo "extra-trusted-public-keys = $key" | sudo tee -a "$target_conf" > /dev/null
            restart_required=1
        fi
    done

    if [ "$restart_required" -eq 1 ]; then
        echo "Restarting nix-daemon to apply cache settings..."
        sudo systemctl restart nix-daemon
    fi
}

if command -v nix &>/dev/null || [ -e /nix/var/nix/profiles/default/bin/nix ]; then
    echo "Nix is already installed"
    configure_nix_caches
    exit 0
fi

echo "Installing Nix (Determinate Systems installer)..."
if [ "${CI:-}" = "true" ]; then
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix \
        | sh -s -- install linux --no-confirm --init none
else
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix \
        | sh -s -- install --no-confirm
fi

configure_nix_caches

echo "Nix installation complete."
echo "Please restart your shell or run: . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
