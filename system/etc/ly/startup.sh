#!/bin/sh
# Executado pelo ly antes de assumir o tty (start_cmd). Instalado por install/ly.sh.
# Troca as 16 cores do console pela paleta Catppuccin Mocha: o config.ini usa full_color = false
# e escolhe as cores por índice, então elas aparecem exatas (o console não tem cor de 24 bits).
# Escreve direto no /dev/tty: a saída padrão do serviço do ly vai para o log, não para a tela.

# 0 base      1 vermelho  2 verde     3 amarelo   4 azul      5 lilás     6 verde-água 7 subtexto
# 8 surface2  9-14 versões claras                                             15 texto
COLORS="1E1E2E F38BA8 A6E3A1 F9E2AF 89B4FA CBA6F7 94E2D5 BAC2DE 585B70 F38BA8 A6E3A1 F9E2AF 89B4FA F5C2E7 94E2D5 CDD6F4"

{
    i=0
    for c in $COLORS; do
        printf '\033]P%x%s' "$i" "$c"
        i=$((i + 1))
    done
    printf '\033[H\033[2J'   # limpa (evita sobras com as cores antigas)
} > /dev/tty 2>/dev/null

exit 0
