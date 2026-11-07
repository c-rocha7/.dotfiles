#!/usr/bin/env bash
# Gera as cores a partir do wallpaper e aplica no Hyprland e no Ghostty (o Quickshell lê o
# ~/.cache/matugen/quickshell.json sozinho). Chamado pelo waypaper a cada troca (post_command
# em waypaper/config.ini), inclusive pelo SUPER+W.
#   aplicar.sh [imagem]      sem imagem: usa o wallpaper atual (awww query)
#   aplicar.sh desligar      volta ao Catppuccin e para de seguir o wallpaper
#   aplicar.sh ligar         volta a seguir o wallpaper (e aplica o atual)
set -u
CACHE="$HOME/.cache/matugen"

if [ "${1:-}" = ligar ]; then
    rm -f "$CACHE/desligado"
    set --
elif [ "${1:-}" = desligar ]; then
    mkdir -p "$CACHE" && touch "$CACHE/desligado"
    rm -f "$CACHE"/quickshell.json "$CACHE"/hypr-cores.lua "$CACHE"/ghostty-cores
    hyprctl eval 'hl.config({ general = { col = { active_border = { colors = { "rgba(33ccffee)", "rgba(00ff99ee)" }, angle = 45 }, inactive_border = "rgba(595959aa)" } } })' >/dev/null
    pkill -USR2 -x ghostty
    exit 0
fi

[ -e "$CACHE/desligado" ] && exit 0
command -v matugen >/dev/null || { echo "matugen não instalado (sudo pacman -S matugen)" >&2; exit 1; }
img=${1:-$(awww query 2>/dev/null | sed -n '1s/.*image: //p')}
[ -f "$img" ] || { echo "wallpaper não encontrado: $img" >&2; exit 1; }

mkdir -p "$CACHE"
matugen image "$img" -m dark --prefer saturation -c "$HOME/.dotfiles/matugen/config.toml" -q || exit 1
hyprctl eval "$(grep -v '^ *--' "$CACHE/hypr-cores.lua" | tr '\n' ' ')" >/dev/null   # sem comentários: "--" vira opção do hyprctl
pkill -USR2 -x ghostty          # Ghostty relê a configuração (inclui o ghostty-cores)
exit 0
