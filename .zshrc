
# User specific environment
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]; then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
if ! [[ "$PATH" =~ "$HOME/.cargo/bin:" ]]; then
    PATH="$HOME/.cargo/bin:$PATH"
fi
if ! [[ "$PATH" =~ "$HOME/.dotnet/tools:" ]]; then
    PATH="$HOME/.dotnet/tools:$PATH"
fi
export PATH

#if [[ "$TERM_PROGRAM" == "ghostty" ]]; then
#    export TERM=xterm-256color
#fi

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

ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#ff00ff,bold,underline"

source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

if [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv zsh)"
fi
