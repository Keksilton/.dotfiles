#!/bin/sh
# CLI-only setup for Alpine Linux (3.22 or newer)
# Safe to re-run: each step checks the current state before changing anything
# Plain POSIX sh on purpose: Alpine has no bash until this script installs it
set -eu

if [ "$(id -u)" -eq 0 ]; then
  echo "Run as your normal user; the script uses doas or sudo where needed." >&2
  exit 1
fi

if command -v doas >/dev/null 2>&1; then
  SUDO=doas
elif command -v sudo >/dev/null 2>&1; then
  SUDO=sudo
else
  echo "Install and configure doas or sudo first." >&2
  exit 1
fi

cd "$(dirname "$(realpath "$0")")"
export PATH="$HOME/.local/bin:$PATH"

has() { command -v "$1" >/dev/null 2>&1; }

# Most of the tools are in the community repo, which some installs leave disabled
community="$(grep -m1 -E '^[^#].*/main/?$' /etc/apk/repositories | sed -E 's|/main/?$|/community|')"
if [ -n "$community" ] && ! grep -qxF "$community" /etc/apk/repositories; then
  echo "$community" | $SUDO tee -a /etc/apk/repositories >/dev/null
fi

$SUDO apk update
# bash: needed by the oh-my-posh installer and TPM (tmux plugins); shadow: provides chsh
$SUDO apk add stow curl ca-certificates unzip bash shadow git zsh zsh-syntax-highlighting zsh-autosuggestions tmux fzf btop tailscale lsd jq delta

# Without an existing ~/.config, stow links the whole folder into the repo
mkdir -p "$HOME/.config"
stow .

# tealdeer (tldr) is only in Alpine's edge/testing repo, so use its static musl build
if ! has tldr; then
  mkdir -p "$HOME/.local/bin"
  curl -fsSL -o "$HOME/.local/bin/tldr.tmp" "https://github.com/tealdeer-rs/tealdeer/releases/latest/download/tealdeer-linux-$(uname -m)-musl"
  chmod +x "$HOME/.local/bin/tldr.tmp"
  mv "$HOME/.local/bin/tldr.tmp" "$HOME/.local/bin/tldr"
  tldr --update
fi

has oh-my-posh || curl -fsSL https://ohmyposh.dev/install.sh | bash -s

# GIT config
git config --global core.pager delta
git config --global interactive.diffFilter 'delta --color-only'
git config --global delta.navigate true

user="$(id -un)"
if [ "$(awk -F: -v u="$user" '$1 == u { print $7 }' /etc/passwd)" != /bin/zsh ]; then
  $SUDO chsh -s /bin/zsh "$user"
fi
