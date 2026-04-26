#!/bin/bash
set -euo pipefail

PASS=0
FAIL=0

check() {
  local desc="$1"
  shift
  if "$@" &>/dev/null; then
    echo "  PASS: $desc"
    ((PASS++))
  else
    echo "  FAIL: $desc"
    ((FAIL++))
  fi
}

echo "=== Smoke Tests ==="

# Config files exist
echo ""
echo "--- Config files ---"
check "git config exists" test -f "${HOME}/.config/git/config"
check "zshrc exists" test -f "${HOME}/.zshrc"
check "zimrc exists" test -f "${HOME}/.zimrc"
check "devbox.json exists" test -f "${HOME}/.local/share/devbox/global/default/devbox.json"

# Git config values
echo ""
echo "--- Git config ---"
check "git user.name set" git config --get user.name
check "git user.signingkey set" git config --get user.signingkey
check "git gpg.format is ssh" test "$(git config --get gpg.format)" = "ssh"
check "git commit.gpgsign is true" test "$(git config --get commit.gpgsign)" = "true"
check "git gpg.ssh.program set" git config --get gpg.ssh.program

# SSH config
echo ""
echo "--- SSH config ---"
check "ssh config exists" test -f "${HOME}/.ssh/config"
check "ssh config has IdentityAgent" grep -q "IdentityAgent" "${HOME}/.ssh/config"

# Devbox
echo ""
echo "--- Devbox ---"
check "devbox is on PATH" command -v devbox

# Devbox global packages (if devbox installed successfully)
if command -v devbox &>/dev/null; then
  check "devbox global list works" devbox global list
fi

# Key binaries from devbox (only if devbox global install succeeded)
echo ""
echo "--- CLI tools ---"
for tool in git gh nvim rg fzf tmux glow yazi; do
  check "$tool on PATH" command -v "$tool"
done

# Zsh starts cleanly
echo ""
echo "--- Shell ---"
check "zsh starts without errors" zsh -il -c 'exit 0'

# Summary
echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
