
# User specific environment
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]; then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
export PATH

# User specific aliases and functions
if [ -d ~/.config/zshrc ]; then
    for rc in ~/.config/zshrc/*; do
        if [ -f "$rc" ]; then
            . "$rc"
        fi
    done
fi
unset rc

source <(fzf --zsh)

if [ "$TERM_PROGRAM" != "Apple_Terminal" ]; then
  eval "$(oh-my-posh init zsh --config '~/.config/oh-my-posh/config.yaml')"
fi

source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
