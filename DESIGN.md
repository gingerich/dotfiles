# Dotfiles Design Spec

One-command bootstrap for a fully configured development machine.

```
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply gingerich
```

## Goals

- **One-step bootstrap:** A single command on a fresh machine installs all tools and applies all configuration.
- **Cross-platform:** macOS (ARM) and Linux. Platform differences handled via chezmoi templates.
- **Reproducible:** Tool versions pinned through devbox (Nix). GUI apps managed via Homebrew casks.
- **Secrets via 1Password:** No plaintext secrets in the repo. SSH keys, tokens, and signing handled through 1Password.
- **Idempotent:** Running `chezmoi apply` again is safe and converges to the desired state.

## Tool Responsibilities

| Tool | Role |
|------|------|
| **chezmoi** | Dotfile management, templating, cross-platform config, bootstrap orchestration via scripts |
| **devbox** | CLI tool installation via Nix (reproducible, pinned versions) |
| **Homebrew** | GUI apps (casks), macOS-specific formulas, fonts |
| **mas** | Mac App Store apps (macOS only) |
| **1Password** | SSH agent, git commit signing, `gh` CLI auth via shell plugin, secrets in chezmoi templates |
| **Zim** | Zsh plugin manager (modules, completions, prompt) |

## Package Split

### devbox global (CLI tools)

All command-line tools go through devbox for reproducibility across macOS and Linux.

- git
- tmux
- gh (GitHub CLI)
- 1password-cli (`op`)
- neovim
- ripgrep
- fzf
- yazi
- glow
- claude-code
- fabric-ai
- gemini-cli
- alacritty
- crush

### Homebrew (GUI apps, macOS-specific)

Brew casks for GUI apps that aren't available or practical through Nix.

**Casks:**
- amethyst (tiling window manager)
- bruno (API client)
- vlc
- warp (terminal)
- font-fira-code-nerd-font

**Formulas:**
- ffmpeg
- mas

**mas (Mac App Store):**
- TBD (add App Store apps as needed)

## Directory Structure

```
dotfiles/
├── home/                               # chezmoi source directory
│   ├── .chezmoi.toml.tmpl              # chezmoi config (OS/arch detection, 1Password, prompts)
│   ├── .chezmoiscripts/
│   │   ├── run_once_before_01-install-devbox.sh.tmpl
│   │   ├── run_once_before_02-install-homebrew.sh.tmpl
│   │   ├── run_onchange_after_devbox-global.sh.tmpl
│   │   ├── run_onchange_after_homebrew-bundle.sh.tmpl
│   │   └── run_onchange_after_zimfw.sh.tmpl
│   ├── dot_config/
│   │   └── git/
│   │       └── config.tmpl             # templated for cross-platform op-ssh-sign path
│   ├── dot_ssh/
│   │   └── modify_config.sh.tmpl       # ensures 1Password agent block without clobbering
│   ├── private_dot_zimrc               # Zim module list
│   ├── private_dot_zshrc.tmpl          # shell config (templated for devbox/1password paths)
│   ├── Brewfile                        # brew bundle manifest (casks, formulas, mas)
│   └── dot_local/
│       └── share/
│           └── devbox/
│               └── global/
│                   └── default/
│                       └── devbox.json # devbox global package list
├── .chezmoiroot                        # tells chezmoi source root is home/
├── DESIGN.md                           # this file
└── README.md
```

## Bootstrap Sequence

chezmoi runs scripts in alphabetical order within each phase. The `before_` / `after_` prefix controls whether scripts run before or after file installation.

### Phase 1: Install package managers (`run_once_before_`)

These run once on first `chezmoi init --apply`, before any config files are placed.

1. **`01-install-devbox.sh.tmpl`** — Install devbox if not present. Skips if `devbox` is already on PATH.
2. **`02-install-homebrew.sh.tmpl`** — Install Homebrew if not present (macOS only via template guard). Skips on Linux.

### Phase 2: Apply config files

chezmoi places all dotfiles:
- `~/.config/git/config` (templated — different op-ssh-sign path per OS)
- `~/.ssh/config` (1Password agent block added via modify script, preserves existing config)
- `~/.zshrc`, `~/.zimrc`
- `~/.local/share/devbox/global/default/devbox.json`
- `~/Brewfile`

### Phase 3: Install packages (`run_onchange_after_`)

These run after file installation, and re-run whenever their content changes (hash-based).

1. **`devbox-global.sh.tmpl`** — Runs `devbox global install`. Re-triggers when `devbox.json` content changes (embed hash in script).
2. **`homebrew-bundle.sh.tmpl`** — Runs `brew bundle --file=~/Brewfile`. macOS only. Re-triggers when Brewfile changes.
3. **`zimfw.sh.tmpl`** — Runs `zimfw install` to sync Zim modules. Re-triggers when `.zimrc` changes.

## Cross-Platform Templating

The `.chezmoi.toml.tmpl` detects OS and arch, making variables available to all templates:

```toml
[data]
  os = {{ .chezmoi.os | quote }}
  arch = {{ .chezmoi.arch | quote }}
```

Key platform differences handled via templates:

| Config | macOS | Linux |
|--------|-------|-------|
| `gpg.ssh.program` | `/Applications/1Password.app/Contents/MacOS/op-ssh-sign` | `/opt/1Password/op-ssh-sign` |
| SSH agent socket | `~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock` | `~/.1password/agent.sock` |
| Homebrew scripts | Enabled | Skipped (empty template) |
| Homebrew path | `/opt/homebrew` (ARM) | N/A |

## Git Authentication & Signing

Git is configured for SSH-based commit signing via 1Password:

```gitconfig
[user]
  name = Marlin Gingerich
  email = marlin@gingerich.io
  signingkey = ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPfGK9X/G6Abf+F8D6cXOYc586FkDIn0jrTFmpyWsDtl

[gpg]
  format = ssh

[gpg "ssh"]
  program = <platform-dependent op-ssh-sign path>

[commit]
  gpgsign = true
```

GitHub CLI auth uses the 1Password shell plugin (`op plugin init gh`), which injects tokens via biometric auth. This is a one-time manual step after bootstrap.

## SSH Config Strategy

chezmoi uses a `modify_` script for `~/.ssh/config` rather than managing the full file. Other tools (OrbStack, Gitpod, Colima, devbox) add their own `Include` directives when installed — we don't want to fight them.

The modify script ensures the 1Password `IdentityAgent` block is present:

```
Host *
    IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
```

On Linux the socket path changes to `~/.1password/agent.sock`. The script is templated for this.

If the block already exists, the script is a no-op. Other tool-managed includes are left untouched.

## Secrets Strategy

- **No secrets in the repo.** All sensitive values come from 1Password at apply time.
- chezmoi's `onepasswordRead` template function fetches secrets: `{{ onepasswordRead "op://vault/item/field" }}`
- SSH keys live in 1Password, exposed via the 1Password SSH agent.
- The signing key public component is hardcoded in git config (it's a public key, no security concern). This avoids requiring 1Password auth during bootstrap.

## Post-Bootstrap Manual Steps

These require interactive auth and can't be fully automated:

1. Sign into 1Password desktop app
2. Enable SSH Agent in 1Password settings (Developer > Set Up SSH Agent)
3. Run `op plugin init gh` to connect GitHub CLI to 1Password

## Testing Strategy

Validation happens at multiple levels to catch issues before they hit a real machine.

### 1. chezmoi dry-run (template & config validation)

Fast, safe, runs on the development machine:

```bash
chezmoi diff                        # show what would change
chezmoi apply --dry-run --verbose   # simulate full apply without writing
```

Catches: template syntax errors, wrong file paths, missing variables, unexpected diffs.

### 2. Docker end-to-end (Linux cold-start)

A Dockerfile in `test/` that simulates a completely fresh machine:

```
test/
├── Dockerfile           # bare Ubuntu/Debian, no tools pre-installed
└── smoke-test.sh        # post-bootstrap verification
```

The Dockerfile runs the full bootstrap one-liner (`curl | sh ... chezmoi init --apply`) against the current branch, then runs smoke tests. This validates:

- devbox installs and all global packages resolve
- chezmoi scripts execute in correct order
- Config files land in the right locations
- Shell starts without errors

Run with: `docker build -f test/Dockerfile .`

### 3. macOS incremental validation

macOS can't be containerized, so we validate on the development machine:

1. `chezmoi diff` first — review before applying
2. `chezmoi apply` — scripts have idempotent guards (`which devbox`, `which brew`), so existing installs are skipped
3. Run smoke tests to verify end state

### 4. Smoke tests

A `test/smoke-test.sh` script that verifies the final state of a bootstrapped machine:

- All expected devbox global packages are installed (`devbox global list`)
- Homebrew bundle is satisfied (`brew bundle check`, macOS only)
- Git config has correct values (`git config user.signingkey`, `git config gpg.format`)
- Key binaries are on PATH (`op`, `gh`, `nvim`, `rg`, `fzf`, `tmux`)
- `zsh -il -c 'exit'` starts and exits cleanly (no syntax errors in shell config)
- `~/.ssh/config` contains 1Password agent socket config
- `~/.config/git/config` exists with expected signing config

### Test directory structure

```
test/
├── Dockerfile           # fresh Ubuntu image, runs full bootstrap
└── smoke-test.sh        # portable checks, runs on both Linux and macOS
```

## Future Considerations (Not in Scope)

- macOS system preferences (`defaults write`) — defer to a later phase
- Neovim plugin/config management (e.g., lazy.nvim) — add once nvim config stabilizes
- Work vs personal machine profiles (different email, different tool sets)
- WSL support
