#!/usr/bin/env bash
# KDE Plasma appearance: Andromeda Kvantum theme and Plasma style, Ayu Dark color scheme and the
# KekDark global theme holding the auto-hiding panel layout
# Run it inside a Plasma session after the CLI setup (needs stow, git and the kvantum package)
# Safe to re-run: each step checks the current state before changing anything
set -euo pipefail

if [[ $EUID -eq 0 ]]; then
  echo "Run as the user whose desktop should be configured." >&2
  exit 1
fi

cd "$(dirname "$(realpath "$0")")"
. ./setup-common.sh

# Fork of https://github.com/EliverLara/Andromeda-kde (GPL-3.0)
ANDROMEDA_REPO=https://github.com/Keksilton/Andromeda-KDE

if ! has plasma-apply-colorscheme; then
  echo "KDE Plasma not found, skipping the desktop appearance setup."
  exit 0
fi

# Set a KDE config key only when it differs; --notify tells running apps about the change
kde_set() {
  if [[ "$(kreadconfig6 --file "$1" --group "$2" --key "$3")" != "$4" ]]; then
    kwriteconfig6 --notify --file "$1" --group "$2" --key "$3" "$4"
  fi
}

# Stowed with the dotfiles: Ayu Dark color scheme (.local/share/color-schemes), the Kvantum theme
# selection (.config/Kvantum/kvantum.kvconfig) and the KekDark global theme (.local/share/plasma/look-and-feel).
# When those folders didn't exist yet, stow linked them (or a parent) as a whole into the repo;
# unfold them so themes installed later stay in the home directory
unfold() {
  local dir="$1"
  while [[ "$dir" != "$HOME" ]]; do
    if [[ -L "$dir" && "$(realpath "$dir")" == "$PWD/"* ]]; then
      rm "$dir"
      break
    fi
    dir="$(dirname "$dir")"
  done
  mkdir -p "$1"
}
unfold "$HOME/.config/Kvantum"
unfold "$HOME/.local/share/color-schemes"
unfold "$HOME/.local/share/plasma/look-and-feel"
stow .

# Andromeda Kvantum theme and Plasma style
kvantum_theme="$HOME/.config/Kvantum/Andromeda"
plasma_style="$HOME/.local/share/plasma/desktoptheme/Andromeda"
if [[ ! -d "$kvantum_theme" || ! -d "$plasma_style" ]]; then
  tmp="$(mktemp -d)"
  git clone --depth 1 "$ANDROMEDA_REPO" "$tmp"
  mkdir -p "$(dirname "$kvantum_theme")" "$(dirname "$plasma_style")"
  [[ -d "$kvantum_theme" ]] || cp -r "$tmp/kvantum/Andromeda" "$kvantum_theme"
  [[ -d "$plasma_style" ]] || cp -r "$tmp/plasma/desktoptheme/Andromeda" "$plasma_style"
  rm -rf "$tmp"
fi

# Global theme KekDark: auto-hiding bottom panel layout plus the defaults set below.
# --resetLayout replaces the current panels and desktops, so apply it only once
if [[ "$(kreadconfig6 --file kdeglobals --group KDE --key LookAndFeelPackage)" != KekDark ]]; then
  plasma-apply-lookandfeel -a KekDark --resetLayout
fi

# Both tools do nothing when the theme is already set
plasma-apply-colorscheme AyuDark
plasma-apply-desktoptheme Andromeda

# Application style Kvantum (the Kvantum theme itself is set in .config/Kvantum/kvantum.kvconfig)
kde_set kdeglobals KDE widgetStyle kvantum
kde_set kdeglobals Icons Theme breeze-dark
