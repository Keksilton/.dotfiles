alias neofetch="fastfetch -c neofetch"
alias ls="lsd"
if command -v podman &>/dev/null; then
  alias start-redis-pod="podman network exists redis-net || podman network create redis-net; podman run --rm --net redis-net --network-alias some-valkey --name some-valkey -p 6379:6379 -d valkey/valkey valkey-server --save 60 1 --loglevel warning"
  alias start-redis-client="podman run -it --net redis-net --rm valkey/valkey valkey-cli -h some-valkey"
  function start-redis {
    if [[ -z "$(podman ps -q --filter name='^some-valkey$')" ]]; then
      start-redis-pod
      sleep 1
    fi
    start-redis-client
  }
fi


alias find-package="pkgs=\$(dnf list --available | fzf --multi --preview 'dnf info {1}' --preview-label-pos='bottom' --preview-window 'down:65%:wrap' --color 'pointer:green,marker:green' --height=100% --border --margin=1 --padding=1 | rg '^(\\S+)' -or '\$1'); if [[ -n \$pkgs ]]; then ; sudo dnf install -y \$pkgs ; fi"

alias update-clickhouse="curl https://clickhouse.com/ | sh ; sudo ./clickhouse install ; rm clickhouse"

alias cobalt="yt-dlp --recode-video mp4 --force-write-archive"

# Claude Code in a rootless podman container: it can only see and write the current directory.
# Login, settings and memory persist in ~/.local/share/claude-box; arguments go to claude
# (e.g. `claude-box --continue`, `claude-box --dangerously-skip-permissions`)
if command -v podman &>/dev/null; then
  typeset -g CLAUDE_BOX_DIR="${${(%):-%x}:A:h}/../../containers/claude"
  function claude-box {
    local image=localhost/claude-box state="$HOME/.local/share/claude-box"
    if ! podman image exists "$image"; then
      podman build -t "$image" "$CLAUDE_BOX_DIR" || return
    fi
    mkdir -p "$state"
    local -a gitconfig
    [[ -f "$HOME/.gitconfig" ]] && gitconfig=(-v "$HOME/.gitconfig:/home/node/.gitconfig:ro,Z")
    podman run --rm -it \
      --userns=keep-id --cap-drop=ALL --security-opt=no-new-privileges \
      --hostname claude-box \
      -v "$state:/home/node/.claude:Z" \
      -v "$PWD:$PWD:Z" -w "$PWD" \
      "${gitconfig[@]}" \
      -e TERM -e COLORTERM \
      "$image" "$@"
  }
fi

# setup-fedora.sh sets kernel.yama.ptrace_scope=1, which blocks attaching a debugger (gdb -p, Rider
# "Attach to Process") to an already running process; allow it temporarily, then restrict again
alias ptrace-allow="sudo sysctl kernel.yama.ptrace_scope=0"
alias ptrace-restrict="sudo sysctl kernel.yama.ptrace_scope=1"
