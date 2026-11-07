#!/usr/bin/env bash
# Adiciona uma agenda (link iCal) em ~/.config/agenda/ical-url, lendo a área de transferência
# SÓ depois do Enter (assim copiar este comando não estraga o link).
#   agenda-adicionar.sh "Família"
set -u
nome=${1:-}
[ -n "$nome" ] || { echo "uso: $0 \"Nome da agenda\""; exit 1; }
F="$HOME/.config/agenda/ical-url"
mkdir -p "$(dirname "$F")"

read -rp "Copie no navegador o link iCal da agenda \"$nome\" e aperte Enter aqui... " _
link=$(wl-paste --no-newline 2>/dev/null | tr -d '[:space:]')
link=${link/#webcal:\/\//https://}

if [[ ! "$link" =~ ^https://.+\.ics$ ]]; then
    echo "Isso não parece um link de agenda (deve começar com https:// e terminar com .ics)."
    echo "Copiado agora: ${link:0:40}..."
    exit 1
fi
if grep -qF "$link" "$F" 2>/dev/null; then
    echo "Essa agenda já está cadastrada."
    exit 0
fi
printf '%s = %s\n' "$nome" "$link" >> "$F"
chmod 600 "$F"
echo "Agenda \"$nome\" adicionada. Agendas cadastradas:"
sed -E 's/ = .*//; s/^/  - /' "$F"
qs ipc call agenda atualizar >/dev/null 2>&1 || true
