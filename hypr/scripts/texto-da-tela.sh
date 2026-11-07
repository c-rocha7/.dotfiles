#!/usr/bin/env bash
# Texto da tela (OCR): selecione uma área e o texto dela vai para a área de transferência.
# Precisa do tesseract (+ tesseract-data-por e -eng). Atalho: SUPER+SHIFT+T (ou o botão na central).
set -u
command -v tesseract >/dev/null || { notify-send -a "Texto da tela" "tesseract não instalado" "sudo pacman -S tesseract tesseract-data-por tesseract-data-eng"; exit 1; }
area=$(slurp 2>/dev/null) || exit 0                       # Esc cancela
texto=$(grim -g "$area" - | tesseract - - -l por+eng 2>/dev/null | sed -e 's/[[:space:]]*$//' | sed -e '/./,$!d')
if [ -z "$texto" ]; then
    notify-send -a "Texto da tela" "Nenhum texto encontrado" "Tente uma área maior ou com mais contraste."
    exit 0
fi
printf '%s' "$texto" | wl-copy
notify-send -a "Texto da tela" "Texto copiado ($(wc -l <<<"$texto") linhas)" "$(head -c 180 <<<"$texto")"
