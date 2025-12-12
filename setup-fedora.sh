sudo dnf copr enable scottames/ghostty

sudo dnf install -y zsh fzf stow zsh-syntax-highlighting zsh-autosuggestions btop lsd kvantum stow ghostty tailscale

stow .

curl -fsSL https://neuralink.com/tsui/install.sh | bash

curl https://clickhouse.com/ | sh
sudo ./clickhouse install
rm clickhouse

curl -s https://ohmyposh.dev/install.sh | bash -s
