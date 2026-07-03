# Prompt: Starship.
# STARSHIP_CONFIG points at the repo-tracked toml so it works on a fresh machine
# before dotbot has linked ~/.config/starship.toml.
export STARSHIP_CONFIG="$HOME/.dotfiles/starship/starship.toml"
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"

  # Transient prompt (Starship has no native zsh support, unlike fish/bash):
  # collapse each submitted prompt to just the char once the command runs.
  # Colors match starship.toml [character].
  _starship_transient_line_init() {
    emulate -L zsh
    [[ $CONTEXT == start ]] || return 0
    while true; do
      zle .recursive-edit
      local -i ret=$?
      [[ $ret == 0 && $KEYS == $'\4' ]] || break
      [[ -o ignore_eof ]] || exit 0
    done
    local saved_prompt=$PROMPT saved_rprompt=$RPROMPT
    PROMPT='%(?.%F{76}.%F{196})❯%f '
    RPROMPT=''
    zle .reset-prompt
    PROMPT=$saved_prompt
    RPROMPT=$saved_rprompt
    if (( ret )); then zle .send-break; else zle .accept-line; fi
    return ret
  }
  zle -N zle-line-init _starship_transient_line_init
fi
