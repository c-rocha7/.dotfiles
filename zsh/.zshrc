bindkey "^[[H" beginning-of-line
bindkey "^[[F" end-of-line
bindkey "^[[3~" delete-char
bindkey "^H" backward-kill-word
bindkey "^[[3;5~" kill-word
bindkey "^[[1;5D" backward-word
bindkey "^[[1;5C" forward-word

source /usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source <(fzf --zsh)

[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

fpath+=/usr/share/zsh/site-functions
autoload -Uz compinit
compinit

export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"

alias ls="eza --icons"
alias ll="ls -la"
alias la="ls -a"
alias bat="bat --style=auto"
alias ff="fastfetch"
alias sail="sh $([ -f sail ] && echo sail || echo vendor/bin/sail)"
alias y="yazi"
alias ..="cd .."
alias ...="cd ../.."
alias doc="cd ~/Documentos"
alias obs="cd Documentos/Obsidian\ Notes/"
