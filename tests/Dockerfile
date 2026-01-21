FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV CI=true

RUN apt-get update && apt-get install -y \
    curl \
    git \
    gpg \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Create test user
RUN useradd -m -s /bin/bash testuser && \
    echo "testuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER testuser
WORKDIR /home/testuser

# Install chezmoi
RUN sh -c "$(curl -fsLS get.chezmoi.io)" -- -b /home/testuser/bin

ENV PATH="/home/testuser/bin:${PATH}"

# Copy dotfiles
COPY --chown=testuser:testuser . /home/testuser/dotfiles

# Run chezmoi
RUN mkdir -p /home/testuser/.local/share && \
    ln -s /home/testuser/dotfiles /home/testuser/.local/share/chezmoi && \
    chezmoi apply --dry-run --verbose
