#!/usr/bin/env bash
# CLI-only setup (no codecs, desktop apps or system tweaks)
# Safe to re-run: each step checks the current state before changing anything
set -euo pipefail

if [[ $EUID -eq 0 ]]; then
  echo "Run as your normal user; the script uses sudo where needed." >&2
  exit 1
fi

cd "$(dirname "$(realpath "$0")")"
export PATH="$HOME/.local/bin:$PATH"

has() { command -v "$1" &>/dev/null; }

sudo dnf install -y stow

stow .

sudo dnf install -y git zsh zsh-syntax-highlighting zsh-autosuggestions tmux fzf btop tailscale lsd jq git-delta tldr

has oh-my-posh || curl -fsSL https://ohmyposh.dev/install.sh | bash -s

# GIT config
git config --global core.pager delta
git config --global interactive.diffFilter 'delta --color-only'
git config --global delta.navigate true

if [[ "$(getent passwd "$USER" | cut -d: -f7)" != /usr/bin/zsh ]]; then
  chsh -s /usr/bin/zsh
fi
