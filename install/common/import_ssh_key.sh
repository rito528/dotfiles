#!/bin/bash

if ! doppler whoami &> /dev/null; then
  echo "Not logged into Doppler. Please run 'doppler login' and run setup.sh apply again."
  exit 1
fi

DOPPLER_PROJECT="keys"
DOPPLER_CONFIG="prd"

echo "Importing SSH keys from Doppler..."

doppler secrets get SSH_PRIVATE_KEY --plain --project "$DOPPLER_PROJECT" --config "$DOPPLER_CONFIG" | tee ~/.ssh/id_rsa > /dev/null
doppler secrets get SSH_PUBLIC_KEY --plain --project "$DOPPLER_PROJECT" --config "$DOPPLER_CONFIG" | tee ~/.ssh/id_rsa.pub > /dev/null

chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/id_rsa.pub

echo "SSH keys imported successfully."
