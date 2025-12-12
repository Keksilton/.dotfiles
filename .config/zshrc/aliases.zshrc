alias neofetch="fastfetch -c neofetch"
alias ls="lsd"
alias start-redis-pod="podman run --rm --net redis-net --network-alias some-valkey --name some-valkey -p 6379:6379 -d valkey/valkey valkey-server --save 60 1 --loglevel warning"
alias start-redis-client="podman run -it --net redis-net --rm valkey/valkey valkey-cli -h some-valkey"
alias start-redis="if [ $(podman container ls --filter name=some-valkey | wc -l) -lt 2 ]; then start-redis-pod ; fi; sleep 1; start-redis-client"


alias find-package="pkgs=\$(dnf list --available | fzf --multi --preview 'dnf info {1}' --preview-label-pos='bottom' --preview-window 'down:65%:wrap' --color 'pointer:green,marker:green' --height=100% --border --margin=1 --padding=1 | rg '^(\\S+)' -or '\$1'); if [[ -n \$pkgs ]]; then ; sudo dnf install -y \$pkgs ; fi"

alias update-clickhouse="curl https://clickhouse.com/ | sh ; sudo ./clickhouse install ; rm clickhouse"
