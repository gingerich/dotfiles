FROM ubuntu:24.04

RUN apt-get update && apt-get install -y \
    curl git zsh xz-utils sudo \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/zsh testuser && \
    echo 'testuser ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
USER testuser
WORKDIR /home/testuser

COPY --chown=testuser:testuser . /home/testuser/.local/share/chezmoi

RUN sh -c "$(curl -fsLS get.chezmoi.io)" -- -b /home/testuser/.local/bin
ENV PATH="/home/testuser/.local/bin:${PATH}"

RUN mkdir -p /home/testuser/.config/chezmoi && \
    printf '[data]\n  profile = "personal"\n' > /home/testuser/.config/chezmoi/chezmoi.toml

SHELL ["/bin/bash", "-c"]

# chezmoi init --apply: installs devbox, places config files.
# devbox global install will fail (nix-daemon can't run in Docker build) — that's expected.
RUN chezmoi init --apply --source /home/testuser/.local/share/chezmoi 2>&1; true

# Validate config files and template rendering
RUN echo "=== Docker Validation ===" && \
    echo "--- Config files ---" && \
    test -f ~/.config/git/config && echo "PASS: git config" && \
    test -f ~/.zshrc && echo "PASS: zshrc" && \
    test -f ~/.zimrc && echo "PASS: zimrc" && \
    test -f ~/Brewfile && echo "PASS: Brewfile" && \
    test -f ~/.local/share/devbox/global/default/devbox.json && echo "PASS: devbox.json" && \
    test -f ~/.ssh/config && echo "PASS: ssh config" && \
    echo "--- Git config values ---" && \
    grep -q "signingkey" ~/.config/git/config && echo "PASS: signingkey present" && \
    grep -q "format = ssh" ~/.config/git/config && echo "PASS: gpg format" && \
    grep -q "/opt/1Password/op-ssh-sign" ~/.config/git/config && echo "PASS: linux op-ssh-sign path" && \
    grep -q "gpgsign = true" ~/.config/git/config && echo "PASS: gpgsign enabled" && \
    echo "--- SSH config ---" && \
    grep -q "IdentityAgent" ~/.ssh/config && echo "PASS: 1password agent" && \
    grep -q "1password/agent.sock" ~/.ssh/config && echo "PASS: linux agent socket path" && \
    echo "--- Devbox ---" && \
    command -v devbox && echo "PASS: devbox installed" && \
    echo "=== All Docker checks passed ==="
