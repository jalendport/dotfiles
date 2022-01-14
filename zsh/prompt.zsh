# Enable Powerlevel10k instant prompt - should stay close to the top of .zshrc
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

source ~/.dotfiles/zsh/prompt/powerlevel10k/powerlevel10k.zsh-theme

# To customize prompt, run `p10k configure` or edit p10k.zsh
[[ ! -f ~/.dotfiles/zsh/prompt/p10k.zsh ]] || source ~/.dotfiles/zsh/prompt/p10k.zsh