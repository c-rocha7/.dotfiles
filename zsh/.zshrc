source /usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

fpath+=/usr/share/zsh/site-functions
autoload -Uz compinit
compinit

export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"

alias ls="exa --icons"
alias bat="bat --style=auto"
alias ff="fastfetch"
alias sail='sh $([ -f sail ] && echo sail || echo vendor/bin/sail)'
