#!/bin/bash
# ログインシェルを zsh に変更する
# setup.sh から呼び出される

set -euo pipefail

# home-manager が Nix 経由で zsh をインストールした場合、現セッションの PATH に
# Nix プロファイルが含まれていないことがある。明示的に source して解決する。
NIX_PROFILE=/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
if [ -e "$NIX_PROFILE" ] && ! command -v zsh &>/dev/null; then
    # shellcheck source=/dev/null
    . "$NIX_PROFILE"
fi

ZSH_PATH="$(command -v zsh)"

# /etc/shells への登録
if ! grep -qF "$ZSH_PATH" /etc/shells; then
    echo "$ZSH_PATH" | sudo tee -a /etc/shells
fi

# ログインシェルの変更
if [ "$SHELL" != "$ZSH_PATH" ]; then
    sudo chsh -s "$ZSH_PATH" "$USER"
    echo "==> Login shell changed to $ZSH_PATH (requires re-login)"
fi
