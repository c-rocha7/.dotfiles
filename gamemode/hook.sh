#!/usr/bin/env bash
# Chamado pelo GameMode (gamemode.ini) quando o primeiro jogo abre ("start")
# e quando o último fecha ("end").
# A ilha (quickshell/GameMode.qml) troca o perfil de energia e mostra o aviso.
# Sem a ilha rodando, troca o perfil direto.

case "$1" in
    start)
        qs ipc call gamemode started 2>/dev/null \
            || powerprofilesctl set performance
        ;;
    end)
        qs ipc call gamemode stopped 2>/dev/null \
            || powerprofilesctl set balanced
        ;;
    *)
        echo "uso: $0 start|end" >&2
        exit 1
        ;;
esac
