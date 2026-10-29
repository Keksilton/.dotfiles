#!/usr/bin/env bash
# CLI-only setup for Debian (13 "trixie" or newer) and Ubuntu
# Safe to re-run: each step checks the current state before changing anything
set -euo pipefail

if [[ $EUID -eq 0 ]]; then
  echo "Run as your normal user; the script uses sudo where needed." >&2
  exit 1
fi

cd "$(dirname "$(realpath "$0")")"
. ./setup-common.sh

sudo apt-get update
sudo apt-get install -y stow curl ca-certificates

# Without an existing ~/.config, stow links the whole folder into the repo
mkdir -p "$HOME/.config"
stow .

# Tailscale isn't in the Debian/Ubuntu repos, so add its apt repo (ID is debian or ubuntu)
if [[ ! -f /etc/apt/sources.list.d/tailscale.list ]]; then
  read -r distro codename < <(. /etc/os-release && echo "$ID $VERSION_CODENAME")
  curl -fsSL "https://pkgs.tailscale.com/stable/$distro/$codename.noarmor.gpg" | sudo tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
  curl -fsSL "https://pkgs.tailscale.com/stable/$distro/$codename.tailscale-keyring.list" | sudo tee /etc/apt/sources.list.d/tailscale.list >/dev/null
  sudo apt-get update
fi

sudo apt-get install -y git zsh zsh-syntax-highlighting zsh-autosuggestions tmux fzf btop tailscale lsd jq git-delta

install_oh_my_posh
configure_git
set_default_shell zsh
