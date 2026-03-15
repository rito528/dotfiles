#!/bin/bash
# Install Docker Engine on Ubuntu (official method)
# https://docs.docker.com/engine/install/ubuntu/
# Usage: ./install/ubuntu/docker.sh

set -euo pipefail

if dpkg -l docker-ce &>/dev/null; then
    echo "Docker is already installed"
else
    echo "Setting up Docker apt repository..."
    sudo apt-get update
    sudo apt-get install -y ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    # shellcheck source=/dev/null
    . /etc/os-release
    echo \
        "Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: ${UBUNTU_CODENAME:-${VERSION_CODENAME}}
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc" \
        | sudo tee /etc/apt/sources.list.d/docker.sources > /dev/null

    sudo apt-get update

    echo "Installing Docker Engine..."
    sudo apt-get install -y \
        docker-ce \
        docker-ce-cli \
        containerd.io \
        docker-buildx-plugin \
        docker-compose-plugin
fi

echo "Enabling Docker service..."
sudo systemctl enable --now docker

if ! groups "$USER" | grep -q '\bdocker\b'; then
    echo "Adding $USER to docker group..."
    sudo usermod -aG docker "$USER"
    echo "NOTE: Re-login required for docker group to take effect."
fi

echo "Docker installation complete."
