#!/usr/bin/env bash
# Fase 2: snapper para o / (subvolume @), com os snapshots no subvolume @snapshots.
#
# Rodar com:  sudo bash fase2-snapper.sh   (depois da fase 1)
#
# - snapshots antes/depois de cada pacman/yay (snap-pac)
# - snapshots periódicos com limite (5 por hora, 7 diários, 2 semanais, 1 mensal)
# - limpeza automática dos antigos
# O /home NÃO entra (é outro subvolume), nem /nix, /var/lib/docker, /var/log e o cache do pacman.

set -euo pipefail

UUID=61b69d0d-6939-4d01-9bfd-a87c1bf4d558 # UUID da partição Btrfs (blkid)
OPTS="rw,noatime,compress=zstd:3,ssd,discard=async,space_cache=v2"

[[ $EUID -eq 0 ]] || { echo "Rode com sudo."; exit 1; }

echo ">> 1/7 Instalando o snapper"
pacman -S --needed snapper

echo ">> 2/7 Criando a configuração 'root'"
if [[ -f /etc/snapper/configs/root ]]; then
    echo "   já existe, mantendo"
else
    snapper -c root create-config /
fi

echo ">> 3/7 Trocando o /.snapshots criado pelo snapper pelo subvolume @snapshots"
if ! mountpoint -q /.snapshots; then
    # O snapper cria /.snapshots DENTRO do @; trocamos pelo @snapshots (fora do @),
    # que é o que permite restaurar o @ inteiro a partir de um snapshot.
    if btrfs subvolume show /.snapshots >/dev/null 2>&1; then
        btrfs subvolume delete /.snapshots
    fi
    mkdir -p /.snapshots
    if ! grep -q 'subvol=/@snapshots' /etc/fstab; then
        cp -a /etc/fstab "/etc/fstab.bak-$(date +%Y%m%d-%H%M%S)"
        printf 'UUID=%s\t/.snapshots\tbtrfs     \t%s,subvol=/@snapshots\t0 0\n' "$UUID" "$OPTS" >> /etc/fstab
    fi
    systemctl daemon-reload
    mount /.snapshots
fi
chmod 750 /.snapshots
mountpoint /.snapshots

echo ">> 4/7 Limites e permissões"
snapper -c root set-config \
    ALLOW_GROUPS=wheel SYNC_ACL=yes \
    NUMBER_CLEANUP=yes NUMBER_LIMIT=10 NUMBER_LIMIT_IMPORTANT=5 \
    TIMELINE_CREATE=yes TIMELINE_CLEANUP=yes \
    TIMELINE_LIMIT_HOURLY=5 TIMELINE_LIMIT_DAILY=7 TIMELINE_LIMIT_WEEKLY=2 \
    TIMELINE_LIMIT_MONTHLY=1 TIMELINE_LIMIT_QUARTERLY=0 TIMELINE_LIMIT_YEARLY=0

echo ">> 5/7 Ativando os timers (snapshots periódicos e limpeza)"
systemctl enable --now snapper-timeline.timer snapper-cleanup.timer

echo ">> 6/7 Instalando snap-pac (snapshots no pacman) e btrfs-assistant (interface gráfica)"
pacman -S --needed snap-pac btrfs-assistant

echo ">> 7/7 Primeiro snapshot (marcado como importante)"
snapper -c root create -c number -u important=yes -d "Base: sistema configurado"

echo
snapper -c root list
echo
echo "Pronto. Ver snapshots: snapper -c root list   |   interface: btrfs-assistant"
