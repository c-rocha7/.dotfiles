#!/usr/bin/env bash
# Manutenção automática:
# - btrfs scrub mensal no disco (confere se algum dado foi corrompido)
# - paccache semanal (apaga versões antigas do cache do pacman, mantém as 3 últimas)
# (fstrim não é necessário: o fstab já usa discard=async)
#
# Rodar com:  sudo bash manutencao.sh

set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "Rode com sudo."; exit 1; }

echo ">> 1/3 Scrub mensal do Btrfs (o '-' representa o /)"
systemctl enable --now btrfs-scrub@-.timer

echo ">> 2/3 Instalando pacman-contrib (paccache, checkupdates, pactree)"
pacman -S --needed pacman-contrib

echo ">> 3/3 Limpeza semanal do cache do pacman"
systemctl enable --now paccache.timer

echo
systemctl list-timers --no-pager btrfs-scrub@-.timer paccache.timer
