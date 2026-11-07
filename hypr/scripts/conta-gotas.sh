#!/usr/bin/env bash
# Conta-gotas: clique em qualquer ponto da tela e o código da cor (hex) vai para a área de transferência.
# Precisa do hyprpicker. Atalho: SUPER+SHIFT+C (ou o botão na central de controle).
set -u
command -v hyprpicker >/dev/null || { notify-send -a "Conta-gotas" "hyprpicker não instalado" "sudo pacman -S hyprpicker"; exit 1; }
cor=$(hyprpicker -a -f hex 2>/dev/null) || exit 0     # Esc cancela
[ -n "$cor" ] && notify-send -a "Conta-gotas" "Cor copiada" "$cor"
