#!/bin/bash

if ! doppler whoami &> /dev/null; then
  echo "Not logged into Doppler. Please run 'doppler login' and run setup.sh apply again."
  exit 1
fi

DOPPLER_PROJECT="keys"
DOPPLER_CONFIG="prd"

echo "Importing GPG keys from Doppler..."

doppler secrets get GPG_PUBKEY --plain --project "$DOPPLER_PROJECT" --config "$DOPPLER_CONFIG" | gpg --import
doppler secrets get GPG_SUBKEYS --plain --project "$DOPPLER_PROJECT" --config "$DOPPLER_CONFIG" | gpg --import
doppler secrets get GPG_OWNERTRUST --plain --project "$DOPPLER_PROJECT" --config "$DOPPLER_CONFIG" | gpg --import-ownertrust

echo "GPG keys imported successfully."
