# ===============================================================
# 1. POWERLEVEL10K INSTANT PROMPT
# ===============================================================
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ===============================================================
# 2. OH MY ZSH CONFIGURATION
# ===============================================================
export ZSH="$HOME/.oh-my-zsh"

# Tema (Usando o que está no repositório do OMZ)
ZSH_THEME="powerlevel10k/powerlevel10k"

# Plugins do Oh My Zsh (Adicione mais aqui se quiser)
plugins=(git mise)

# Inicializa o Oh My Zsh
source $ZSH/oh-my-zsh.sh

# ===============================================================
# 2.1. CONFIGURAÇÕES DE HISTÓRICO (APENAS SESSÃO)
# ===============================================================
# Remove o arquivo de persistência e zera a gravação no disco
unset HISTFILE
SAVEHIST=0

# Mantém apenas na memória para a aba atual
HISTSIZE=1000

# Garante que as abas não fiquem "fofocando" o histórico uma para a outra
unsetopt share_history
unsetopt append_history

# ===============================================================
# 3. TECLAS DE ATALHO (BINDKEYS)
# ===============================================================
bindkey "^[[H" beginning-of-line
bindkey "^[[F" end-of-line
bindkey "^[[3~" delete-char
bindkey "^H" backward-kill-word
bindkey "^[[3;5~" kill-word
bindkey "^[[1;5D" backward-word
bindkey "^[[1;5C" forward-word

# ===============================================================
# 4. FERRAMENTAS E GERENCIADORES (MISE, FZF, ETC)
# ===============================================================
# FZF
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh || source <(fzf --zsh)

# MISE
eval "$(~/.local/bin/mise activate zsh)"

# Função de atualização
mi-update-all() {
  sudo pacman -Syu mise
  mise upgrade
  mise install
  echo "🚀 Sistema e ferramentas atualizados!"
}

# ===============================================================
# 5. VARIÁVEIS DE AMBIENTE E LOCALIZAÇÃO
# ===============================================================
export LANG=pt_BR.UTF-8
export LC_ALL=pt_BR.UTF-8

# ===============================================================
# 6. ALIASES
# ===============================================================
alias ls="eza --icons"
alias ll="ls -la"
alias la="ls -a"
alias bat="bat --style=auto"
alias ff="fastfetch"
alias sail="[ -f sail ] && sh sail || sh vendor/bin/sail"
alias y="yazi"
alias compile="cc -Wall -Wextra -Werror"
alias ..="cd .."
alias ...="cd ../.."
alias spotify="spotify_player"

# Mise Shortcuts
alias mi="mise"
alias mi-i="mise install"
alias mi-u="mise upgrade"
alias mi-s="mise doctor"
alias mi-l="mise ls"
alias mi-clean="mise prune --dry-run"
alias mi-purge="mise prune -y"

# ===============================================================
# 7. SYNTAX HIGHLIGHTING & AUTOSUGGESTIONS (SEMPRE NO FINAL)
# ===============================================================
# Carregando dos diretórios do sistema (Arch Linux)
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

# Configuração específica do Powerlevel10k (Deve vir após o tema ser carregado)
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
