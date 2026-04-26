# dotfiles

One-command bootstrap for a fully configured development machine.

## Quick Start

On a fresh machine:

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply gingerich
```

This single command:

1. Installs chezmoi
2. Clones this repo
3. Installs devbox and Homebrew (macOS)
4. Installs all CLI tools via devbox and GUI apps via Homebrew
5. Applies all configuration (git, ssh, zsh, etc.)

## Post-Bootstrap

These require interactive auth and can't be fully automated:

1. Sign into 1Password desktop app
2. Enable SSH Agent in 1Password settings (Developer > Set Up SSH Agent)
3. Run `op plugin init gh` to connect GitHub CLI to 1Password

## How It Works

| Tool | Role |
|------|------|
| [chezmoi](https://chezmoi.io) | Dotfile management, templating, bootstrap orchestration |
| [devbox](https://www.jetify.com/devbox) | CLI tools via Nix (reproducible, pinned) |
| [Homebrew](https://brew.sh) | GUI apps and macOS-specific packages |
| [1Password](https://1password.com) | SSH agent, git signing, secrets |
| [Zim](https://zimfw.sh) | Zsh plugin manager |

## Updating

After changing config files:

```bash
chezmoi apply
```

## Platforms

- macOS (ARM)
- Linux
