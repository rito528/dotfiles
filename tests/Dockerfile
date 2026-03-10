FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV CI=true

RUN apt-get update && apt-get install -y \
    curl \
    git \
    gpg \
    sudo \
    xz-utils \
    && rm -rf /var/lib/apt/lists/*

# Create test user
RUN useradd -m -s /bin/bash testuser && \
    echo "testuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER testuser
WORKDIR /home/testuser

# Install Nix
RUN curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | \
    sh -s -- install linux --no-confirm --init none

ENV PATH="/nix/var/nix/profiles/default/bin:${PATH}"

# Copy dotfiles
COPY --chown=testuser:testuser . /home/testuser/dotfiles

# Validate home-manager build (dry-run equivalent)
RUN . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh && \
    nix run nixpkgs#home-manager -- build \
      --flake /home/testuser/dotfiles/nix \
      --impure
