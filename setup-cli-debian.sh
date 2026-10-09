#!/usr/bin/env bash
# CLI-only setup for Debian (13 "trixie" or newer)
# Safe to re-run: each step checks the current state before changing anything
set -euo pipefail

if [[ $EUID -eq 0 ]]; then
  echo "Run as your normal user; the script uses sudo where needed." >&2
  exit 1
fi

cd "$(dirname "$(realpath "$0")")"
export PATH="$HOME/.local/bin:$PATH"

has() { command -v "$1" &>/dev/null; }

sudo apt-get update
sudo apt-get install -y stow curl ca-certificates unzip

stow .

# Tailscale isn't in the Debian repos, so add its apt repo
if [[ ! -f /etc/apt/sources.list.d/tailscale.list ]]; then
  codename="$(. /etc/os-release && echo "$VERSION_CODENAME")"
  curl -fsSL "https://pkgs.tailscale.com/stable/debian/$codename.noarmor.gpg" | sudo tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
  curl -fsSL "https://pkgs.tailscale.com/stable/debian/$codename.tailscale-keyring.list" | sudo tee /etc/apt/sources.list.d/tailscale.list >/dev/null
  sudo apt-get update
fi

sudo apt-get install -y git zsh zsh-syntax-highlighting zsh-autosuggestions tmux fzf btop tailscale lsd jq git-delta tldr

has oh-my-posh || curl -fsSL https://ohmyposh.dev/install.sh | bash -s

# GIT config
git config --global core.pager delta
git config --global interactive.diffFilter 'delta --color-only'
git config --global delta.navigate true

if [[ "$(getent passwd "$USER" | cut -d: -f7)" != /usr/bin/zsh ]]; then
  chsh -s /usr/bin/zsh
fi
