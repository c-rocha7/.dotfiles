#!/usr/bin/env bash
# Tela externa (HDMI, DisplayPort, USB-C): alterna o modo com SUPER+SHIFT+P (ou a tecla de projetor).
#   estender  → externa à direita do notebook, na resolução ideal (padrão ao conectar)
#   espelhar  → externa mostra o mesmo que o notebook (apresentação, TV)
#   externo   → só a externa (notebook apagado)
#   notebook  → só o notebook (externa desligada)
# Uso: monitor.sh [proximo|estender|espelhar|externo|notebook]   (sem argumento = proximo)

INTERNAL=eDP-1
INTERNAL_SPEC='mode = "1920x1080@60", position = "0x0", scale = 1'
STATE="${XDG_RUNTIME_DIR:-/tmp}/monitor-modo"
MODES=(estender espelhar externo notebook)

ext=$(hyprctl monitors all -j | jq -r --arg i "$INTERNAL" '[.[] | select(.name != $i)][0].name // empty')
if [[ -z $ext ]]; then
    notify-send -a "Monitor" -i video-display -t 2500 "Nenhuma tela externa" "Conecte um monitor, TV ou projetor."
    exit 0
fi

mode=${1:-proximo}
if [[ $mode == proximo ]]; then
    current=$(cat "$STATE" 2>/dev/null || echo estender)
    for i in "${!MODES[@]}"; do
        [[ ${MODES[$i]} == "$current" ]] && mode=${MODES[$(( (i + 1) % ${#MODES[@]} ))]}
    done
    [[ $mode == proximo ]] && mode=espelhar
fi

apply() { hyprctl eval "$1" >/dev/null; }
case $mode in
    estender)
        apply "hl.monitor({ output = \"$INTERNAL\", $INTERNAL_SPEC })"
        apply "hl.monitor({ output = \"$ext\", mode = \"preferred\", position = \"auto-right\", scale = 1 })"
        msg="Estendida: $ext à direita" ;;
    espelhar)
        apply "hl.monitor({ output = \"$INTERNAL\", $INTERNAL_SPEC })"
        apply "hl.monitor({ output = \"$ext\", mode = \"preferred\", position = \"auto\", scale = 1, mirror = \"$INTERNAL\" })"
        msg="Espelhada: $ext igual ao notebook" ;;
    externo)
        apply "hl.monitor({ output = \"$ext\", mode = \"preferred\", position = \"0x0\", scale = 1 })"
        apply "hl.monitor({ output = \"$INTERNAL\", disabled = true })"
        msg="Só a tela externa ($ext)" ;;
    notebook)
        apply "hl.monitor({ output = \"$INTERNAL\", $INTERNAL_SPEC })"
        apply "hl.monitor({ output = \"$ext\", disabled = true })"
        msg="Só a tela do notebook" ;;
    *) echo "uso: $0 [proximo|estender|espelhar|externo|notebook]"; exit 1 ;;
esac
echo "$mode" > "$STATE"
notify-send -a "Monitor" -i video-display -t 2500 "Tela externa" "$msg"
