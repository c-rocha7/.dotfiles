#!/usr/bin/env bash
# Saúde do SSD: smartmontools + smartd vigiando o NVMe, com aviso na ilha.
#
# Rodar com:  sudo bash ssd-saude.sh
#
# 1. instala o smartmontools
# 2. /etc/smartd.conf e /etc/smartmontools/smartd-notificar.sh (cópias em system/etc)
# 3. liga o smartd e mostra o estado atual do SSD
# 4. manda uma notificação de teste (tem que aparecer na ilha)
#
# Ver a saúde depois:  sudo smartctl -a /dev/nvme0
# Desfazer: sudo systemctl disable --now smartd; restaure /var/backups/ssd-smartd.conf-* (se houver)

set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "Rode com sudo."; exit 1; }
SRC="$(dirname "$(readlink -f "$0")")/../system/etc"
STAMP=$(date +%Y%m%d-%H%M%S)

echo ">> 1/4 smartmontools"
pacman -S --needed smartmontools

echo ">> 2/4 Configuração do smartd"
mkdir -p /var/backups
[[ -f /etc/smartd.conf ]] && cp -a /etc/smartd.conf "/var/backups/ssd-smartd.conf-$STAMP"
install -m 644 "$SRC/smartd.conf" /etc/smartd.conf
install -D -m 755 "$SRC/smartmontools/smartd-notificar.sh" /etc/smartmontools/smartd-notificar.sh

echo ">> 3/4 Ligando o smartd"
systemctl enable --now smartd
systemctl restart smartd
sleep 2
systemctl --no-pager --lines=5 status smartd || true

echo
echo "----- Saúde do SSD agora -----"
smartctl -H /dev/nvme0 | grep -iE 'overall|result' || true
smartctl -A /dev/nvme0 | grep -E 'Critical Warning|Temperature:|Available Spare|Percentage Used|Data Units Written|Power On Hours|Unsafe Shutdowns|Media and Data Integrity Errors|Error Information Log Entries' || true

echo
echo ">> 4/4 Notificação de teste (confira na ilha)"
SMARTD_DEVICE=/dev/nvme0 SMARTD_FAILTYPE=Teste \
SMARTD_MESSAGE="Teste do aviso de saúde do SSD: está tudo funcionando." \
    /etc/smartmontools/smartd-notificar.sh
echo "Pronto."
