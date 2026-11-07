#!/usr/bin/env bash
# Sessão de trabalho: abre o que faltar do conjunto do dia, cada um na sua workspace
# (regras do hyprland.lua): Zen (1), VS Code (2), terminal (3) e o Obsidian escondido (SUPER+O).
# Termina na workspace 2. Atalho: SUPER+SHIFT+Return.
set -u
aberto() { hyprctl clients -j | jq -e --arg c "$1" 'any(.[]; .class | test($c))' >/dev/null; }

aberto '^zen-beta$' || setsid -f zen-beta >/dev/null 2>&1
aberto '^(com\.microsoft\.VSCode|code|Code)$' || setsid -f code >/dev/null 2>&1
hyprctl clients -j | jq -e 'any(.[]; .workspace.id == 3 and .class == "com.mitchellh.ghostty")' >/dev/null ||
    hyprctl dispatch 'hl.dsp.exec_cmd("ghostty", { workspace = "3 silent" })' >/dev/null
aberto '^(obsidian|md\.obsidian\.Obsidian)$' || setsid -f obsidian >/dev/null 2>&1   # vai para o special:notas

sleep 1
hyprctl dispatch 'hl.dsp.focus({ workspace = 2 })' >/dev/null
