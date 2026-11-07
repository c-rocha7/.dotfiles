#!/usr/bin/env bash
# Janelas escondidas (scratchpads): mostra/esconde um app numa workspace especial própria.
#   scratchpad.sh <nome> <classe (regex)> <comando...>
# Se o app não estiver aberto, abre (a regra "scratchpad-<nome>" do hyprland.lua manda a janela
# para special:<nome>, flutuando) e mostra quando ela aparecer. Atalhos no hyprland.lua.
set -u
nome=$1 classe=$2
shift 2

aberto() { hyprctl clients -j | jq -e --arg c "$classe" 'any(.[]; .class | test($c))' >/dev/null; }
visivel() { hyprctl monitors -j | jq -e --arg w "special:$nome" 'any(.[]; .specialWorkspace.name == $w)' >/dev/null; }
alternar() { hyprctl dispatch "hl.dsp.workspace.toggle_special(\"$nome\")" >/dev/null; }

if aberto; then
    alternar
    exit 0
fi

setsid -f "$@" >/dev/null 2>&1
for _ in $(seq 100); do          # espera até 10 s (Spotify/Obsidian demoram a abrir)
    sleep 0.1
    if aberto; then
        visivel || alternar
        exit 0
    fi
done
