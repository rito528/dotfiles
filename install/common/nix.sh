#!/bin/bash
# Install Nix package manager
# Usage: ./install/common/nix.sh

set -euo pipefail

NUMTIDE_SUBSTITUTER="https://cache.numtide.com"
NUMTIDE_PUBLIC_KEY="niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="

configure_numtide_cache() {
    local nix_conf="/etc/nix/nix.conf"
    local nix_custom_conf="/etc/nix/nix.custom.conf"
    local target_conf="$nix_conf"
    local restart_required=0

    if grep -q '^!include nix\.custom\.conf$' "$nix_conf" 2>/dev/null; then
        target_conf="$nix_custom_conf"
        sudo touch "$target_conf"
    fi

    if grep -qF "$NUMTIDE_SUBSTITUTER" "$target_conf" 2>/dev/null; then
        echo "Numtide cache is already configured in $target_conf"
    else
        echo "Configuring Numtide cache in $target_conf..."
        echo "extra-trusted-substituters = $NUMTIDE_SUBSTITUTER" | sudo tee -a "$target_conf" > /dev/null
        restart_required=1
    fi

    if grep -qF "$NUMTIDE_PUBLIC_KEY" "$target_conf" 2>/dev/null; then
        echo "Numtide cache public key is already configured in $target_conf"
    else
        echo "Configuring Numtide cache public key in $target_conf..."
        echo "extra-trusted-public-keys = $NUMTIDE_PUBLIC_KEY" | sudo tee -a "$target_conf" > /dev/null
        restart_required=1
    fi

    if grep -qE "(^|[[:space:]])${USER}([[:space:]]|$)" "$target_conf" 2>/dev/null; then
        echo "$USER is already trusted in $target_conf"
    else
        echo "Granting trusted Nix access to $USER in $target_conf..."
        echo "extra-trusted-users = $USER" | sudo tee -a "$target_conf" > /dev/null
        restart_required=1
    fi

    if [ "$restart_required" -eq 1 ]; then
        echo "Restarting nix-daemon to apply cache settings..."
        sudo systemctl restart nix-daemon
    fi
}

if command -v nix &>/dev/null || [ -e /nix/var/nix/profiles/default/bin/nix ]; then
    echo "Nix is already installed"
    configure_numtide_cache
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

configure_numtide_cache

echo "Nix installation complete."
echo "Please restart your shell or run: . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
