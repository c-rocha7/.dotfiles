#!/usr/bin/env bash
# Snapshots do /home (snapper, config "home"): proteção contra arquivo apagado/sobrescrito sem querer.
# ATENÇÃO: ficam no mesmo SSD. NÃO substituem backup (não protegem de disco queimado ou roubo).
#
# Rodar com:  sudo bash snapshots-home.sh     (feche a Steam antes)
#
# 1. ~/.cache e ~/.local/share/Steam viram subvolumes próprios: ficam FORA dos snapshots
#    (mudam o tempo todo / são grandes e se baixam de novo). O conteúdo é copiado com reflink
#    (instantâneo, sem ocupar espaço a mais).
# 2. snapper create-config para /home (cria /home/.snapshots)
# 3. limites: 24 por hora, 7 por dia, 4 por semana, 3 por mês; grupo wheel lê sem sudo
# 4. primeiro snapshot
#
# Recuperar um arquivo: copie de /home/.snapshots/<N>/snapshot/7aauac/... (ou use o btrfs-assistant).
#   Listar: snapper -c home list      Diferenças: snapper -c home status <N>..0
# Desfazer: sudo snapper -c home delete-config   (apaga a config e os snapshots do /home)

set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "Rode com sudo."; exit 1; }
USER_NAME=7aauac
HOME_DIR=/home/$USER_NAME
STAMP=$(date +%Y%m%d-%H%M%S)

echo ">> 1/4 Conferindo"
[[ $(findmnt -no FSTYPE /home) == btrfs ]] || { echo "/home não é Btrfs. Abortando."; exit 1; }
findmnt -no SOURCE /home | grep -q '\[/@home\]' || { echo "/home não é o subvolume @home. Abortando."; exit 1; }
command -v snapper >/dev/null || { echo "snapper não instalado. Abortando."; exit 1; }
if pgrep -x steam >/dev/null || pgrep -x steamwebhelper >/dev/null; then
    echo "A Steam está aberta: feche-a (inclusive na bandeja) e rode de novo."; exit 1
fi

# Transforma uma pasta em subvolume próprio, mantendo o conteúdo (cópia reflink).
to_subvolume() {
    local dir=$1 disposable=${2:-no}
    if btrfs subvolume show "$dir" >/dev/null 2>&1; then
        echo "   $dir já é subvolume"; return
    fi
    if [[ -e $dir ]]; then
        mv "$dir" "$dir.antigo-$STAMP"
        btrfs subvolume create "$dir" >/dev/null
        if ! cp -a --reflink=always "$dir.antigo-$STAMP/." "$dir/"; then
            # Cache em uso pode ter sockets/arquivos que não copiam: tudo bem, é descartável.
            [[ $disposable == yes ]] || { echo "Falha ao copiar $dir (original em $dir.antigo-$STAMP). Abortando."; exit 1; }
            echo "   aviso: alguns itens do cache não foram copiados (descartável)"
        fi
        rm -rf "$dir.antigo-$STAMP"
    else
        mkdir -p "$(dirname "$dir")"
        btrfs subvolume create "$dir" >/dev/null
    fi
    chown "$USER_NAME:$USER_NAME" "$dir"
    chmod 700 "$dir"
    echo "   $dir → subvolume (fora dos snapshots)"
}

echo ">> 2/4 Pastas fora dos snapshots"
to_subvolume "$HOME_DIR/.cache" yes
to_subvolume "$HOME_DIR/.local/share/Steam"
chmod 755 "$HOME_DIR/.local/share/Steam"   # a Steam não precisa de 700; mantém o padrão dela

echo ">> 3/4 Config 'home' do snapper"
if snapper list-configs | awk 'NR>2 {print $1}' | grep -qx home; then
    echo "   config 'home' já existe"
else
    snapper -c home create-config /home
fi
snapper -c home set-config \
    ALLOW_GROUPS="wheel" SYNC_ACL="yes" \
    TIMELINE_CREATE="yes" TIMELINE_CLEANUP="yes" TIMELINE_MIN_AGE="1800" \
    TIMELINE_LIMIT_HOURLY="24" TIMELINE_LIMIT_DAILY="7" TIMELINE_LIMIT_WEEKLY="4" \
    TIMELINE_LIMIT_MONTHLY="3" TIMELINE_LIMIT_YEARLY="0" \
    NUMBER_CLEANUP="yes" NUMBER_LIMIT="10" SPACE_LIMIT="0.3" FREE_LIMIT="0.2"
systemctl is-enabled --quiet snapper-timeline.timer || systemctl enable --now snapper-timeline.timer
systemctl is-enabled --quiet snapper-cleanup.timer || systemctl enable --now snapper-cleanup.timer

echo ">> 4/4 Primeiro snapshot"
snapper -c home create -d "inicial (snapshots-home.sh)" --cleanup-algorithm number
snapper -c home list | tail -3
echo
echo "Pronto. Os próximos snapshots são automáticos (de hora em hora)."
