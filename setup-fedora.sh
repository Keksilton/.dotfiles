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

# stow, git, zsh, oh-my-posh, tmux and the other CLI tools
bash ./setup-cli-fedora.sh

if [[ ! -f /etc/yum.repos.d/_copr:copr.fedorainfracloud.org:scottames:ghostty.repo ]]; then
  sudo dnf copr enable -y scottames/ghostty
fi

#sudo yum install -y yum-utils
#sudo yum-config-manager --add-repo https://packages.clickhouse.com/rpm/clickhouse.repo

#sudo yum install -y clickhouse-server clickhouse-client

has tsui || curl -fsSL https://neuralink.com/tsui/install.sh | bash

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

# Appearance
# Kvantum theme: Andromeda https://store.kde.org/p/2036824
# Color scheme: Ayu
# SDDM: Andromeda palsma 6 https://store.kde.org/p/2144475

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
