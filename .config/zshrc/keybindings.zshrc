# Emacs keymap even when EDITOR/VISUAL points at vi
bindkey -e

# zsh doesn't switch the terminal to keypad "application mode" by itself, so Home/End arrive
# as different codes depending on the terminal and on what the previous program left behind.
# Enable it while the line editor is active so the terminfo codes below always match.
if (( ${+terminfo[smkx]} && ${+terminfo[rmkx]} )); then
  zle-line-init() { echoti smkx }
  zle-line-finish() { echoti rmkx }
  zle -N zle-line-init
  zle -N zle-line-finish
fi

# bind-all <widget> <key>...: bind every given (non-empty) key sequence to the widget
bind-all() {
  local widget=$1 key
  shift
  for key; do
    [[ -n $key ]] && bindkey "$key" "$widget"
  done
}

# terminfo code first, then the raw sequences of xterm/ghostty, tmux, linux console and rxvt
bind-all beginning-of-line   "${terminfo[khome]}" '^[[H' '^[OH' '^[[1~' '^[[7~'
bind-all end-of-line         "${terminfo[kend]}"  '^[[F' '^[OF' '^[[4~' '^[[8~'
bind-all delete-char         "${terminfo[kdch1]}" '^[[3~'
# emacs-forward-word stops at the end of the word like bash, forward-word would jump to the start of the next one
bind-all emacs-forward-word  '^[[1;5C' '^[[5C' '^[Oc' '^[[1;3C'   # Ctrl+Right (Alt+Right too)
bind-all backward-word       '^[[1;5D' '^[[5D' '^[Od' '^[[1;3D'   # Ctrl+Left  (Alt+Left too)
bind-all kill-word           '^[[3;5~'                            # Ctrl+Delete
bind-all backward-kill-word  '^H' '^[^?'                          # Ctrl+Backspace (ghostty sends ^H)
unfunction bind-all

# Stop word motions at / . - = like bash does, instead of jumping over whole paths and options
WORDCHARS='*?_[]~&;!#$%^(){}<>'
