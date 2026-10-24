#!/usr/bin/env bash
# Safe to re-run: each step checks the current state before changing anything
set -euo pipefail

if [[ $EUID -eq 0 ]]; then
  echo "Run as your normal user; the script uses sudo where needed." >&2
  exit 1
fi

cd "$(dirname "$(realpath "$0")")"
. ./setup-common.sh
export PATH="$HOME/.dotnet/tools:$PATH"

TSUI_VERSION=v0.2.0
TSUI_SHA256_X86_64=ccfcc1408ad695e671cc1272ae9969d9960a48890faf12015c1134cc641fd667
TSUI_SHA256_AARCH64=218a477c5afcf4d63b0670de27a394bf4c78a16ca838289a1bdcdfc9b506a982

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

# Pinned tsui release, downloaded directly instead of running https://neuralink.com/tsui/install.sh
if ! has tsui; then
  case "$(uname -m)" in
    x86_64)  sha=$TSUI_SHA256_X86_64 ;;
    aarch64) sha=$TSUI_SHA256_AARCH64 ;;
    *) echo "No tsui build for $(uname -m)" >&2; exit 1 ;;
  esac
  tmp="$(mktemp)"
  fetch "https://github.com/neuralinkcorp/tsui/releases/download/$TSUI_VERSION/tsui-linux-$(uname -m)" "$tmp" "$sha"
  sudo install -m 755 "$tmp" /usr/local/bin/tsui
  rm -f "$tmp"
fi

# Codecs
if ! installed rpmfusion-free-release rpmfusion-nonfree-release; then
  sudo dnf install -y "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"
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

# KDE Plasma appearance (themes, colors, panel layout)
bash ./setup-kde.sh

# Firewall: Fedora's default FedoraWorkstation zone opens every port above 1024.
# public only allows ssh, mdns and dhcpv6-client, and nothing listens on those unless enabled
sudo systemctl enable --now firewalld
if [[ "$(sudo firewall-cmd --get-default-zone)" != public ]]; then
  sudo firewall-cmd --set-default-zone=public
fi

# LLMNR (Link-Local Multicast Name Resolution) is unauthenticated, deprecated even by Windows 11,
# and nothing on Linux needs it (mDNS via Avahi handles .local names). Drop-in instead of editing
# /usr/lib/systemd/resolved.conf, which package updates overwrite
sudo mkdir -p /etc/systemd/resolved.conf.d
if write_file /etc/systemd/resolved.conf.d/llmnr.conf $'[Resolve]\nLLMNR=no'; then
  sudo systemctl restart systemd-resolved
fi

# Kernel hardening: hide kernel addresses from unprivileged users and only let a process ptrace
# its own children. The latter blocks "attach to running process" in gdb/strace/Rider; use the
# ptrace-allow / ptrace-restrict aliases from aliases.zshrc when you need that
sysctl_conf='# Managed by setup-fedora.sh
kernel.kptr_restrict = 1
kernel.yama.ptrace_scope = 1'
if write_file /etc/sysctl.d/90-hardening.conf "$sysctl_conf"; then
  sudo sysctl -q -p /etc/sysctl.d/90-hardening.conf
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
