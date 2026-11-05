#!/usr/bin/env bash
# Gravação de tela com o gpu-screen-recorder (codifica na GPU: leve para CPU e bateria).
#
#   record.sh start region|screen none|desktop|both   começa (região pede seleção com o mouse)
#   record.sh stop                                    para e salva
#   record.sh toggle region|screen                    sem a ilha: começa (som do PC) ou para
#   record.sh status                                  sai com 0 se estiver gravando
#
# Áudio: none = sem áudio, desktop = som do PC, both = som do PC + microfone.
# Os vídeos vão para ~/Vídeos/Gravações. A ilha do Quickshell é avisada ao começar/parar.

dir="$(xdg-user-dir VIDEOS 2>/dev/null || echo "$HOME/Vídeos")/Gravações"
run="${XDG_RUNTIME_DIR:-/tmp}"
pidfile="$run/record.pid"
filefile="$run/record.file"

running() {
    [ -f "$pidfile" ] && kill -0 "$(cat "$pidfile")" 2>/dev/null
}

start() {
    running && exit 0
    local mode="${1:-screen}" audio="${2:-desktop}" target=()

    if [ "$mode" = "region" ]; then
        local region
        region=$(slurp -f "%wx%h+%x+%y") || exit 0 # seleção cancelada (Esc)
        target=(-w region -region "$region")
    else
        local monitor
        monitor=$(hyprctl monitors | awk '/^Monitor/{n=$2} /focused: yes/{print n}')
        target=(-w "${monitor:-screen}")
    fi

    local sound=()
    case "$audio" in
        desktop) sound=(-a default_output) ;;
        both) sound=(-a "default_output|default_input") ;;
    esac

    mkdir -p "$dir"
    local file="$dir/Gravação_$(date +%Y-%m-%d_%H-%M-%S).mp4"
    setsid gpu-screen-recorder "${target[@]}" "${sound[@]}" -f 60 -o "$file" \
        >"$run/record.log" 2>&1 &
    echo $! >"$pidfile"
    echo "$file" >"$filefile"

    sleep 0.6
    if ! running; then
        notify-send -a "Gravação" -u critical "Não foi possível gravar" "$(tail -3 "$run/record.log")"
        rm -f "$pidfile"
        exit 1
    fi
    qs ipc call recording started >/dev/null 2>&1
}

stop() {
    running || exit 0
    local pid file
    pid=$(cat "$pidfile")
    file=$(cat "$filefile")
    kill -INT "$pid"
    # Espera terminar de salvar (até 10 s).
    for _ in $(seq 50); do kill -0 "$pid" 2>/dev/null || break; sleep 0.2; done
    rm -f "$pidfile"
    qs ipc call recording stopped >/dev/null 2>&1

    local action
    action=$(timeout 600 notify-send -a "Gravação" -i video-x-generic \
        "Gravação salva" "$(basename "$file") · clique para assistir" \
        -A "default=Assistir" -A "folder=Abrir pasta" --wait)
    case "$action" in
        default) xdg-open "$file" ;;
        folder) xdg-open "$dir" ;;
    esac
}

case "$1" in
    start) start "$2" "$3" ;;
    stop) stop ;;
    toggle) if running; then stop; else start "$2" desktop; fi ;;
    status) running ;;
    *) echo "uso: $0 start region|screen none|desktop|both | stop | toggle region|screen | status" >&2; exit 1 ;;
esac
