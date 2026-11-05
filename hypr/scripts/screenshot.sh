#!/usr/bin/env bash
# Print com o hyprshot + notificação com miniatura.
# Clicar na notificação abre o satty para editar (setas, texto, desfoque, recorte).
#
#   screenshot.sh region   seleciona uma região
#   screenshot.sh window   clica numa janela
#   screenshot.sh output   tela inteira (o monitor em foco, sem precisar clicar)
#   screenshot.sh edit     seleciona uma região e já abre no satty
#
# O print é salvo em $HYPRSHOT_DIR (~/Imagens/Prints) e copiado para a área de transferência.

mode="${1:-region}"
open_editor=false
if [ "$mode" = "edit" ]; then
    mode=region
    open_editor=true
fi
dir="${HYPRSHOT_DIR:-$HOME/Imagens/Prints}"
file="Print_$(date +%Y-%m-%d_%H-%M-%S).png"
path="$dir/$file"

extra=()
[ "$mode" = "output" ] && extra=(-m active) # monitor em foco, sem seleção

hyprshot -m "$mode" "${extra[@]}" -o "$dir" -f "$file" --silent
[ -f "$path" ] || exit 0 # seleção cancelada (Esc)

# Edita no satty: Enter salva por cima do original e copia; Esc fecha (o original fica).
edit() {
    satty --filename "$path" --output-filename "$path" --copy-command wl-copy \
        --actions-on-enter save-to-clipboard,save-to-file,exit --early-exit
}

if $open_editor; then
    edit
    exit 0
fi

# Espera o clique na notificação (no máximo 10 min).
action=$(timeout 600 notify-send -a "Captura" -i "$path" \
    "Print salvo" "Copiado para a área de transferência · clique para editar" \
    -A "default=Editar" -A "folder=Abrir pasta" --wait)

case "$action" in
    default) edit ;;
    folder)
        xdg-open "$dir" ;;
esac
