#!/usr/bin/env bash
# CLI-only setup for Fedora (no codecs, desktop apps or system tweaks)
# Safe to re-run: each step checks the current state before changing anything
set -euo pipefail

if [[ $EUID -eq 0 ]]; then
  echo "Run as your normal user; the script uses sudo where needed." >&2
  exit 1
fi

cd "$(dirname "$(realpath "$0")")"
. ./setup-common.sh

sudo dnf install -y stow

# Without an existing ~/.config, stow links the whole folder into the repo
mkdir -p "$HOME/.config"
stow .

sudo dnf install -y git zsh zsh-syntax-highlighting zsh-autosuggestions tmux fzf btop tailscale lsd jq git-delta tldr

install_oh_my_posh
configure_git
set_default_shell zsh
