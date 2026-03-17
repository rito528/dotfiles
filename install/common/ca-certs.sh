#!/bin/bash
# Install CA certificate from Doppler into system trust store
# Usage: ./install/common/ca-certs.sh

set -euo pipefail

CERT_NAME="corporate-ca"
CERT_PATH="/usr/local/share/ca-certificates/${CERT_NAME}.crt"

# CI環境ではスキップ
if [ "${CI:-}" = "true" ]; then
  echo "CI environment detected, skipping CA cert installation"
  exit 0
fi

# すでにインストール済みならスキップ（冪等性）
if [ -f "$CERT_PATH" ]; then
  echo "CA cert already installed at $CERT_PATH, skipping"
  exit 0
fi

# Doppler 認証チェック
if ! doppler whoami &>/dev/null; then
  echo "Warning: Doppler not authenticated, skipping CA cert installation"
  exit 0
fi

echo "Installing CA certificate..."
doppler secrets get CA_CERT --plain --project keys --config prd | sudo tee "$CERT_PATH" > /dev/null
sudo chmod 644 "$CERT_PATH"
sudo update-ca-certificates

echo "CA certificate installed successfully"
