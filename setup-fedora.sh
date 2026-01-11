sudo dnf copr enable scottames/ghostty


sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://packages.clickhouse.com/rpm/clickhouse.repo

sudo yum install -y clickhouse-server clickhouse-client

curl -fsSL https://neuralink.com/tsui/install.sh | bash
curl -s https://ohmyposh.dev/install.sh | bash -s


# Codecs
sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
sudo dnf config-manager setopt fedora-cisco-openh264.enabled=1
sudo dnf update -y @core

sudo dnf swap -y ffmpeg-free ffmpeg --allowerasing
sudo dnf update -y @multimedia --setopt="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin
sudo dnf swap -y mesa-va-drivers mesa-va-drivers-freeworld
sudo dnf swap -y mesa-vdpau-drivers mesa-vdpau-drivers-freeworld

# Apps

sudo dnf install -y discord zsh fzf stow zsh-syntax-highlighting zsh-autosuggestions btop lsd kvantum ghostty tailscale tldr delta dotnet-sdk-9.0 dotnet-sdk-8.0 dotnet-sdk-10.0 kmodtool akmods mokutil openssl jq awscli2 python3.12 python3.9 python 3.13 podman cargo

## dotnet tools
dotnet tool install -g csharprepl 

## flatpaks
flatpak install -y flathub com.brave.Browser org.gimp.GIMP com.bitwarden.desktop md.obsidian.Obsidian


# Appearance
# Kvantum theme: Andromeda https://store.kde.org/p/2036824
# Color scheme: Ayu
# SDDM: Andromeda palsma 6 https://store.kde.org/p/2144475

# WIP TPM Decryption setup (secure boot)
## Example /etc/crypttab
## luks-<UUID> UUID=<UUID> none tpm2-device=auto,discard
## luks-<UUID> UUID=<UUID> /path/to/keyfile luks
# sudo systemd-cryptenroll --wipe-slot=tpm2 --tpm2-device=auto --tpm2-pcrs=1+4+5+7 /dev/nvme2n1p3
sudo grubby --args="rd.luks.options=tpm2-device=auto" --update-kernel=ALL



# Common fixes

sudo bash -c "echo 'options hid_apple fnmode=2' > /etc/modprobe.d/hid_apple.conf"

sudo dracut -fv

stow .

source ~/.zshrc
