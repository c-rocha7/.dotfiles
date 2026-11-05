#!/usr/bin/env bash
# Ajustes de segurança e estabilidade do sistema.
#
# Rodar com:  sudo bash ajustes-sistema.sh
#
# 1. /boot só para o root: no fstab, fmask=0077,dmask=0077 (antes 0022: qualquer usuário lia
#    a partição de boot; o systemd avisava "world accessible, which is a security hole").
# 2. earlyoom: com a memória acabando, encerra o processo que mais usa memória antes do
#    sistema travar (nunca o Hyprland, a ilha ou o áudio). Config: system/etc/default/earlyoom.
#    Obs.: o systemd-oomd não serve aqui: os apps abertos pelo Hyprland ficam no mesmo cgroup
#    da sessão, e ele mataria a sessão inteira.
#
# Desfazer: restaure /var/backups/ajustes-fstab-* para /etc/fstab;
#           sudo systemctl disable --now earlyoom && sudo pacman -Rns earlyoom

set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "Rode com sudo."; exit 1; }
DOTFILES_SYSTEM="$(dirname "$(readlink -f "$0")")/../system"
STAMP=$(date +%Y%m%d-%H%M%S)

echo ">> 1/2 /boot só para o root"
if grep -qE '^\S+\s+/boot\s+vfat\s+\S*fmask=0077' /etc/fstab; then
    echo "   já está com fmask=0077"
else
    grep -qE '^\S+\s+/boot\s+vfat\s+\S*fmask=0022,dmask=0022' /etc/fstab \
        || { echo "Linha do /boot no fstab diferente do esperado. Abortando."; exit 1; }
    mkdir -p /var/backups
    cp -a /etc/fstab "/var/backups/ajustes-fstab-$STAMP"
    sed -i -E '/^\S+\s+\/boot\s+vfat/ s/fmask=0022,dmask=0022/fmask=0077,dmask=0077/' /etc/fstab
    findmnt --verify --tab-file /etc/fstab >/dev/null || {
        echo "fstab inválido depois da mudança: restaurando o backup."
        cp -a "/var/backups/ajustes-fstab-$STAMP" /etc/fstab; exit 1; }
    systemctl daemon-reload
    # A FAT não troca as permissões num remount: desmonta e monta de novo.
    if umount /boot 2>/dev/null && mount /boot; then
        echo "   /boot remontado"
    else
        mountpoint -q /boot || mount /boot
        echo "   /boot em uso agora: as permissões novas valem depois de reiniciar"
    fi
fi
findmnt -no OPTIONS /boot

echo ">> 2/2 earlyoom"
pacman -S --needed earlyoom
[[ -f /etc/default/earlyoom ]] && cp -a /etc/default/earlyoom "/var/backups/ajustes-earlyoom-$STAMP"
install -m 644 "$DOTFILES_SYSTEM/etc/default/earlyoom" /etc/default/earlyoom
systemctl enable --now earlyoom
systemctl restart earlyoom
sleep 1
systemctl --no-pager --lines=4 status earlyoom

echo
echo "Pronto. Reinicie se o /boot não pôde ser remontado."
