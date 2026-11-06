#!/usr/bin/env bash
# Minitela: libera a porta da tela para o usuário logado (regra do udev) e instala o serviço que
# apaga a minitela no boot, antes da tela de login (se minitela/config.json tiver "inicio": "apagada").
#
# Rodar com:  sudo bash minitela.sh
# Depois (sem sudo), o serviço: systemctl --user enable --now ~/.dotfiles/minitela/minitela.service
#
# Desfazer: sudo rm /etc/udev/rules.d/70-minitela.rules && sudo udevadm control --reload
#           sudo systemctl disable minitela-apagar && sudo rm -r /usr/local/lib/minitela /etc/systemd/system/minitela-apagar.service

set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "Rode com sudo."; exit 1; }
SYS="$(dirname "$(readlink -f "$0")")/../system"
SRC="$SYS/etc"
USER_NAME=${SUDO_USER:-7aauac}

echo ">> 1/3 Regra do udev"
install -D -m 644 "$SRC/udev/rules.d/70-minitela.rules" /etc/udev/rules.d/70-minitela.rules
udevadm control --reload-rules
udevadm trigger --subsystem-match=tty
udevadm settle

echo ">> 2/3 Conferindo"
ls -l /dev/minitela 2>/dev/null || { echo "  /dev/minitela não apareceu (a minitela está conectada?)"; exit 1; }
port=$(readlink -f /dev/minitela)
getfacl -p "$port" 2>/dev/null | grep -E "^user:$USER_NAME:rw" \
    && echo "  ok: $USER_NAME pode usar $port" \
    || { echo "  !! sem permissão para $USER_NAME em $port (está logado na tela do notebook?)"; exit 1; }

echo ">> 3/3 Apagar a minitela no boot (antes do login)"
install -D -m 755 -o root -g root "$SYS/usr/local/lib/minitela/apagar-no-boot.py" /usr/local/lib/minitela/apagar-no-boot.py
install -D -m 644 "$SRC/systemd/system/minitela-apagar.service" /etc/systemd/system/minitela-apagar.service
systemctl daemon-reload
systemctl enable minitela-apagar.service
systemctl is-enabled minitela-apagar.service
echo "Pronto. No próximo boot a minitela já começa apagada (o botão acende)."
