FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV CI=true

# Minimum packages needed to run the setup scripts
RUN apt-get update && apt-get install -y sudo curl && rm -rf /var/lib/apt/lists/*

# Create test user
RUN useradd -m -s /bin/bash testuser && \
    echo "testuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER testuser
ENV USER=testuser
WORKDIR /home/testuser

# Copy dotfiles
COPY --chown=testuser:testuser . /home/testuser/dotfiles

# 1. Install apt packages via actual script
RUN bash /home/testuser/dotfiles/install/ubuntu/packages.sh

# 2. Install Nix via actual script (CI=true causes --init none to be used)
RUN bash /home/testuser/dotfiles/install/common/nix.sh

ENV PATH="/nix/var/nix/profiles/default/bin:${PATH}"

# 3. Run home-manager switch via actual script
RUN . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh && \
    sudo /nix/var/nix/profiles/default/bin/nix-daemon & \
    for i in $(seq 1 30); do \
        nix store ping --store daemon 2>/dev/null && break; \
        sleep 1; \
    done && \
    bash /home/testuser/dotfiles/install/common/home-manager.sh
