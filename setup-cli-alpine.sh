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
. ./setup-common.sh

TEALDEER_VERSION=v1.9.0
TEALDEER_SHA256_X86_64=dc7263b550e90c0689ea2cb434e3144469805d5dddecbb1f7fc534e1185b7408
TEALDEER_SHA256_AARCH64=a748f181c00933980cb850f4a24199c45900fc523787f6c524232a6bfc66b895

# Most of the tools are in the community repo, which some installs leave disabled
community="$(grep -m1 -E '^[^#].*/main/?$' /etc/apk/repositories | sed -E 's|/main/?$|/community|')"
if [ -n "$community" ] && ! grep -qxF "$community" /etc/apk/repositories; then
  echo "$community" | $SUDO tee -a /etc/apk/repositories >/dev/null
fi

$SUDO apk update
# bash: needed by TPM (tmux plugins); shadow: provides chsh
$SUDO apk add stow curl ca-certificates bash shadow git zsh zsh-syntax-highlighting zsh-autosuggestions tmux fzf btop tailscale lsd jq delta

# Without an existing ~/.config, stow links the whole folder into the repo
mkdir -p "$HOME/.config"
stow .

# tealdeer (tldr): Alpine only ships it in edge/testing, so use the static musl build
if ! has tldr; then
  case "$(uname -m)" in
    x86_64)  sha=$TEALDEER_SHA256_X86_64 ;;
    aarch64) sha=$TEALDEER_SHA256_AARCH64 ;;
    *) echo "No tealdeer build for $(uname -m)" >&2; exit 1 ;;
  esac
  mkdir -p "$HOME/.local/bin"
  fetch "https://github.com/tealdeer-rs/tealdeer/releases/download/$TEALDEER_VERSION/tealdeer-linux-$(uname -m)-musl" "$HOME/.local/bin/tldr.tmp" "$sha"
  chmod +x "$HOME/.local/bin/tldr.tmp"
  mv "$HOME/.local/bin/tldr.tmp" "$HOME/.local/bin/tldr"
  tldr --update
fi

install_oh_my_posh
configure_git
set_default_shell zsh
