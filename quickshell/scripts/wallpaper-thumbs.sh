#!/usr/bin/env bash
# Lista os wallpapers da pasta e garante uma miniatura para cada um (vipsthumbnail).
#   wallpaper-thumbs.sh <pasta> <pasta-das-miniaturas>
# Saída: uma linha por imagem, "caminho<TAB>miniatura", na ordem alfabética.
# A miniatura só é refeita se a imagem for mais nova que ela.

dir="$1"
thumbs="$2"
mkdir -p "$thumbs"

find "$dir" -maxdepth 1 -type f \
    \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' -o -iname '*.gif' \) \
    -print0 | sort -z | while IFS= read -r -d '' img; do
    thumb="$thumbs/$(printf '%s' "$img" | md5sum | cut -c1-16).jpg"
    if [ ! -s "$thumb" ] || [ "$img" -nt "$thumb" ]; then
        vipsthumbnail "$img" --size 320x180 --smartcrop attention -o "$thumb[Q=85]" 2>/dev/null || continue
    fi
    printf '%s\t%s\n' "$img" "$thumb"
done
