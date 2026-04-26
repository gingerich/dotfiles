FROM ubuntu:24.04

# Minimal dependencies for bootstrap
RUN apt-get update && apt-get install -y \
    curl \
    git \
    zsh \
    xz-utils \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user (chezmoi shouldn't run as root)
RUN useradd -m -s /bin/zsh testuser
USER testuser
WORKDIR /home/testuser

# Copy the dotfiles repo in (instead of cloning from GitHub)
COPY --chown=testuser:testuser . /home/testuser/.local/share/chezmoi

# Install chezmoi
RUN sh -c "$(curl -fsLS get.chezmoi.io)" -- -b /home/testuser/.local/bin

ENV PATH="/home/testuser/.local/bin:${PATH}"

# Run chezmoi init and apply (non-interactive: pre-supply config)
RUN mkdir -p /home/testuser/.config/chezmoi && \
    echo '[data]\n  profile = "personal"' > /home/testuser/.config/chezmoi/chezmoi.toml

RUN chezmoi init --apply --source /home/testuser/.local/share/chezmoi

# Run smoke tests
COPY --chown=testuser:testuser test/smoke-test.sh /home/testuser/smoke-test.sh
RUN chmod +x /home/testuser/smoke-test.sh && /home/testuser/smoke-test.sh
