#!/usr/bin/env bash
# Brilho em passos de 5% que dá para perceber em toda a faixa.
#
#   brightness.sh up     sobe 5%
#   brightness.sh down   desce 5%
#   brightness.sh get    mostra a porcentagem atual (usada pela ilha do Quickshell)
#   brightness.sh set N  define N% (0–100; controle da central de controle)
#
# 0% = o mínimo útil desta tela (abaixo de ~10% do valor do hardware ela não escurece mais)
# 100% = o máximo. No meio, uma curva suave (expoente 2): passos mais finos no escuro.

MIN=0.10   # piso da tela (fração do brilho máximo do hardware)
EXP=2      # curva: 1 = linear, 2 = suave
STEP=5     # tamanho do passo, em %

read -r cur max < <(brightnessctl -m | awk -F, '{print $3, $5}')

# Porcentagem atual na escala 0–100 (de MIN até o máximo, na curva)
pct=$(awk -v c="$cur" -v m="$max" -v min="$MIN" -v e="$EXP" 'BEGIN {
    f = (c / m - min) / (1 - min); if (f < 0) f = 0; if (f > 1) f = 1
    printf "%d", f ^ (1 / e) * 100 + 0.5 }')

case "$1" in
    get) echo "$pct"; exit 0 ;;
    up) pct=$(( (pct + STEP) / STEP * STEP )) ;;
    down) pct=$(( (pct - 1) / STEP * STEP )) ;;
    set) [[ ${2:-} =~ ^[0-9]+$ ]] || { echo "uso: $0 set 0-100" >&2; exit 1; }; pct=$2 ;;
    *) echo "uso: $0 up|down|get|set N" >&2; exit 1 ;;
esac
(( pct > 100 )) && pct=100
(( pct < 0 )) && pct=0

raw=$(awk -v p="$pct" -v m="$max" -v min="$MIN" -v e="$EXP" 'BEGIN {
    printf "%d", m * (min + (1 - min) * (p / 100) ^ e) + 0.5 }')
brightnessctl -q set "$raw"

# Avisa a ilha (se o Quickshell estiver rodando)
qs ipc call brightness changed >/dev/null 2>&1 || true
