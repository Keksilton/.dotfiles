# shellcheck shell=sh
# Shared steps for the setup-*.sh scripts; source it after cd-ing into the repo
# POSIX sh on purpose: Alpine runs it under busybox before bash is installed
# Expects curl, git, sha256sum and getent to be present

OMP_VERSION=v31.9.1
OMP_SHA256_X86_64=574074a4e84797180e0bda0d133da5f01fbda89ecdb450134c7e566b9a389212
OMP_SHA256_AARCH64=a04e7aed0d233ac861161c0f3d4d70912b0747764fd5b10f6bd19c0b6510eb49

# Alpine sets SUDO to doas or sudo before sourcing this file
SUDO="${SUDO:-sudo}"

export PATH="$HOME/.local/bin:$PATH"

has() { command -v "$1" >/dev/null 2>&1; }

# Download $1 to $2 and abort unless its SHA-256 is $3
fetch() {
  curl -fsSL -o "$2" "$1"
  if ! echo "$3  $2" | sha256sum -c - >/dev/null; then
    rm -f "$2"
    echo "Checksum mismatch for $1" >&2
    exit 1
  fi
}

# Pinned oh-my-posh release, downloaded directly instead of running https://ohmyposh.dev/install.sh
install_oh_my_posh() {
  has oh-my-posh && return 0
  case "$(uname -m)" in
    x86_64)  arch=amd64; sha=$OMP_SHA256_X86_64 ;;
    aarch64) arch=arm64; sha=$OMP_SHA256_AARCH64 ;;
    *) echo "No oh-my-posh build for $(uname -m)" >&2; exit 1 ;;
  esac
  mkdir -p "$HOME/.local/bin"
  fetch "https://cdn.ohmyposh.dev/releases/$OMP_VERSION/posh-linux-$arch" "$HOME/.local/bin/oh-my-posh.tmp" "$sha"
  chmod +x "$HOME/.local/bin/oh-my-posh.tmp"
  mv "$HOME/.local/bin/oh-my-posh.tmp" "$HOME/.local/bin/oh-my-posh"
}

configure_git() {
  git config --global core.pager delta
  git config --global interactive.diffFilter 'delta --color-only'
  git config --global delta.navigate true
}

# Make $1 (a command name, e.g. zsh) the login shell of the current user
set_default_shell() {
  shell="$(command -v "$1")"
  user="$(id -un)"
  if [ "$(getent passwd "$user" | cut -d: -f7)" != "$shell" ]; then
    $SUDO chsh -s "$shell" "$user"
  fi
}
