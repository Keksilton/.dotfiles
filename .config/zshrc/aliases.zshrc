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
