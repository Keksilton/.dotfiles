#!/usr/bin/env bash
# Safe to re-run: each step checks the current state before changing anything
set -euo pipefail

if [[ $EUID -eq 0 ]]; then
  echo "Run as your normal user; the script uses sudo where needed." >&2
  exit 1
fi

cd "$(dirname "$(realpath "$0")")"
export PATH="$HOME/.local/bin:$HOME/.dotnet/tools:$PATH"

has() { command -v "$1" &>/dev/null; }
installed() { rpm -q "$@" &>/dev/null; }

# Swap package $1 for $2 only while $1 is still installed
swap() {
  if installed "$1"; then
    sudo dnf swap -y "$1" "$2" "${@:3}"
  fi
}

# Write $2 to file $1 only if the content differs; returns 1 when unchanged
write_file() {
  if [[ -f "$1" && "$(cat "$1")" == "$2" ]]; then
    return 1
  fi
  echo "$2" | sudo tee "$1" >/dev/null
}

# Set a KDE config key only when it differs; --notify tells running apps about the change
kde_set() {
  if [[ "$(kreadconfig6 --file "$1" --group "$2" --key "$3")" != "$4" ]]; then
    kwriteconfig6 --notify --file "$1" --group "$2" --key "$3" "$4"
  fi
}

# Create the KDE folders first so stow links only our files instead of folding whole folders into the repo
mkdir -p "$HOME/.config/Kvantum" "$HOME/.local/share/color-schemes"

# stow, git, zsh, oh-my-posh, tmux and the other CLI tools
bash ./setup-cli-fedora.sh

if [[ ! -f /etc/yum.repos.d/_copr:copr.fedorainfracloud.org:scottames:ghostty.repo ]]; then
  sudo dnf copr enable -y scottames/ghostty
fi

#sudo yum install -y yum-utils
#sudo yum-config-manager --add-repo https://packages.clickhouse.com/rpm/clickhouse.repo

#sudo yum install -y clickhouse-server clickhouse-client

# Pinned tsui release, downloaded directly instead of running https://neuralink.com/tsui/install.sh
if ! has tsui; then
  sudo curl -fsSL -o /usr/local/bin/tsui.tmp "https://github.com/neuralinkcorp/tsui/releases/download/v0.2.0/tsui-linux-$(uname -m)"
  sudo chmod +x /usr/local/bin/tsui.tmp
  sudo mv /usr/local/bin/tsui.tmp /usr/local/bin/tsui
fi

# Codecs
if ! installed rpmfusion-free-release rpmfusion-nonfree-release; then
  sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
fi
sudo dnf config-manager setopt fedora-cisco-openh264.enabled=1
sudo dnf update -y @core

swap ffmpeg-free ffmpeg --allowerasing
sudo dnf update -y @multimedia --setopt="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin
swap mesa-va-drivers mesa-va-drivers-freeworld
swap mesa-vdpau-drivers mesa-vdpau-drivers-freeworld

# Apps

sudo dnf install -y kvantum ghostty dotnet-sdk-9.0 dotnet-sdk-8.0 dotnet-sdk-10.0 kmodtool akmods mokutil openssl awscli2 python3.12 python3.9 python3.13 podman cargo neovim gcc-c++ cmake extra-cmake-modules steam --skip-unavailable

## dotnet tools
if ! grep -qw csharprepl <<<"$(dotnet tool list -g)"; then
  dotnet tool install -g csharprepl
fi

## flatpaks
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install -y flathub com.brave.Browser org.gimp.GIMP com.bitwarden.desktop md.obsidian.Obsidian org.telegram.desktop tv.plex.PlexDesktop

# Appearance (KDE Plasma)
# Stowed with the dotfiles: Ayu Dark color scheme (.local/share/color-schemes) and the Kvantum
# theme selection (.config/Kvantum/kvantum.kvconfig). The Andromeda themes come from a fork of
# https://github.com/EliverLara/Andromeda-kde (GPL-3.0)
if has plasma-apply-colorscheme; then
  kvantum_theme="$HOME/.config/Kvantum/Andromeda"
  plasma_style="$HOME/.local/share/plasma/desktoptheme/Andromeda"
  if [[ ! -d "$kvantum_theme" || ! -d "$plasma_style" ]]; then
    tmp="$(mktemp -d)"
    git clone --depth 1 https://github.com/Keksilton/Andromeda-KDE "$tmp"
    mkdir -p "$(dirname "$kvantum_theme")" "$(dirname "$plasma_style")"
    [[ -d "$kvantum_theme" ]] || cp -r "$tmp/kvantum/Andromeda" "$kvantum_theme"
    [[ -d "$plasma_style" ]] || cp -r "$tmp/plasma/desktoptheme/Andromeda" "$plasma_style"
    rm -rf "$tmp"
  fi

  ## Both tools do nothing when the theme is already set
  plasma-apply-colorscheme AyuDark
  plasma-apply-desktoptheme Andromeda

  ## Application style Kvantum (the Kvantum theme itself is set in .config/Kvantum/kvantum.kvconfig)
  kde_set kdeglobals KDE widgetStyle kvantum
  kde_set kdeglobals Icons Theme breeze-dark
fi

# WIP TPM Decryption setup (secure boot)
## Example /etc/crypttab
## luks-<UUID> UUID=<UUID> none tpm2-device=auto,discard
## luks-<UUID> UUID=<UUID> /path/to/keyfile luks
# sudo systemd-cryptenroll --wipe-slot=tpm2 --tpm2-device=auto --tpm2-pcrs=1+4+5+7 /dev/nvme2n1p3
kernel_args="$(sudo grubby --info=ALL | grep '^args=')"
if grep -qv 'rd.luks.options=tpm2-device=auto' <<<"$kernel_args"; then
  sudo grubby --args="rd.luks.options=tpm2-device=auto" --update-kernel=ALL
fi



# Common fixes

# Only rebuild the initramfs when the modprobe config actually changed
if write_file /etc/modprobe.d/hid_apple.conf 'options hid_apple fnmode=2'; then
  sudo dracut -fv
fi
