fpath=(~/.local/share/zinit/completions $fpath)

# The following lines were added by compinstall
zstyle ':completion:*' completer _expand _complete _ignored
zstyle ':completion:*' matcher-list 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}'

autoload bashcompinit && bashcompinit
autoload -Uz compinit
compinit
# End of lines added by compinstall

# Fedora/Debian and Alpine install the plugin in different places
for plugin in /usr/share/{,zsh/plugins/}zsh-autosuggestions/zsh-autosuggestions.zsh; do
  [[ -f $plugin ]] && source $plugin && break
done
unset plugin

# zsh parameter completion for the dotnet CLI

_dotnet_zsh_complete()
{
  local completions=("$(dotnet complete "$words")")

  # If the completion list is empty, just continue with filename selection
  if [ -z "$completions" ]
  then
    _arguments '*::arguments: _normal'
    return
  fi

  # This is not a variable assignment, don't remove spaces!
  _values = "${(ps:\n:)completions}"
}

compdef _dotnet_zsh_complete dotnet

complete -C '/usr/bin/aws_completer' aws
