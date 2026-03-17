#!/bin/bash
# ログインシェルを zsh に変更する
# setup.sh から呼び出される

set -euo pipefail

ZSH_PATH="$(command -v zsh)"

# /etc/shells への登録
if ! grep -qF "$ZSH_PATH" /etc/shells; then
    echo "$ZSH_PATH" | sudo tee -a /etc/shells
fi

# ログインシェルの変更
if [ "$SHELL" != "$ZSH_PATH" ]; then
    chsh -s "$ZSH_PATH"
    echo "==> Login shell changed to $ZSH_PATH (requires re-login)"
fi
