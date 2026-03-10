#!/usr/bin/env bash
set -euo pipefail

if command -v secretlint &>/dev/null; then
  echo "secretlint is already installed. Skipping."
  exit 0
fi

echo "Installing secretlint..."
npm install -g secretlint @secretlint/secretlint-rule-preset-recommend
