#!/usr/bin/env bash
# Minitela: libera a porta da tela para o usuário logado (regra do udev).
#
# Rodar com:  sudo bash minitela.sh
# Depois (sem sudo), o serviço: systemctl --user enable --now ~/.dotfiles/minitela/minitela.service
#
# Desfazer: sudo rm /etc/udev/rules.d/70-minitela.rules && sudo udevadm control --reload

set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "Rode com sudo."; exit 1; }
SRC="$(dirname "$(readlink -f "$0")")/../system/etc"
USER_NAME=${SUDO_USER:-7aauac}

echo ">> 1/2 Regra do udev"
install -D -m 644 "$SRC/udev/rules.d/70-minitela.rules" /etc/udev/rules.d/70-minitela.rules
udevadm control --reload-rules
udevadm trigger --subsystem-match=tty
udevadm settle

echo ">> 2/2 Conferindo"
ls -l /dev/minitela 2>/dev/null || { echo "  /dev/minitela não apareceu (a minitela está conectada?)"; exit 1; }
port=$(readlink -f /dev/minitela)
getfacl -p "$port" 2>/dev/null | grep -E "^user:$USER_NAME:rw" \
    && echo "  ok: $USER_NAME pode usar $port" \
    || { echo "  !! sem permissão para $USER_NAME em $port (está logado na tela do notebook?)"; exit 1; }
