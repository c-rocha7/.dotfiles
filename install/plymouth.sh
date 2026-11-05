#!/usr/bin/env bash
# Tela de carregamento no boot (Plymouth) com a mesma cena do Limine e do ly: estrelas piscando,
# logo do Arch e anel girando. Esconde o texto do kernel/systemd (ESC durante o boot mostra).
#
#   sudo bash plymouth.sh            aplica
#   sudo bash plymouth.sh desfazer   volta ao boot com texto
#
# 1. instala o plymouth e o tema "noite-catppuccin" (gerado por install/gen_ly_dur.py)
# 2. hook "plymouth" no /etc/mkinitcpio.conf (depois do "systemd")
# 3. opções do kernel em /etc/default/limine: quiet splash loglevel=3 ...
# 4. plymouth-quit padrão: o --retain-splash deixava o tty1 em modo gráfico e o "chvt 2" do ly
#    esperava 5 s (o ly com kmscon não troca de tty sozinho; ver ly-kmsconvt@tty2.service.d)
# 5. Limine com "terse" (sem "Loading kernel...") e initramfs/menu refeitos pelo limine-tema.sh
#    (que roda o limine-update, regrava o hash do menu, assina e confere tudo)

set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "Rode com sudo."; exit 1; }
DIR="$(dirname "$(readlink -f "$0")")"
SRC="$DIR/../system"
THEME=noite-catppuccin
PARAMS="quiet splash loglevel=3 rd.udev.log_level=3 systemd.show_status=auto rd.systemd.show_status=auto"
STAMP=$(date +%Y%m%d-%H%M%S)
mkdir -p /var/backups

backup() { cp -a "$1" "/var/backups/plymouth-$(basename "$1")-$STAMP"; }

aplicar() {
    echo ">> 1/5 Plymouth e o tema $THEME"
    pacman -S --needed plymouth
    rm -rf "/usr/share/plymouth/themes/$THEME"
    install -d "/usr/share/plymouth/themes/$THEME"
    install -m 644 "$SRC/usr/share/plymouth/themes/$THEME/"* "/usr/share/plymouth/themes/$THEME/"
    plymouth-set-default-theme "$THEME"
    [[ $(plymouth-set-default-theme) == "$THEME" ]] || { echo "Tema não ficou ativo. Abortando."; exit 1; }

    echo ">> 2/5 Hook plymouth no mkinitcpio"
    if ! grep -qE '^HOOKS=\(.*\bplymouth\b' /etc/mkinitcpio.conf; then
        backup /etc/mkinitcpio.conf
        sed -i -E '/^HOOKS=\(/ s/\bsystemd\b/systemd plymouth/' /etc/mkinitcpio.conf
    fi
    grep -E '^HOOKS=' /etc/mkinitcpio.conf
    grep -qE '^HOOKS=\(base systemd plymouth ' /etc/mkinitcpio.conf || { echo "HOOKS inesperado. Confira o /etc/mkinitcpio.conf."; exit 1; }

    echo ">> 3/5 Opções do kernel (/etc/default/limine)"
    if ! grep -qE '^KERNEL_CMDLINE\[default\]\+=.*\bsplash\b' /etc/default/limine; then
        backup /etc/default/limine
        sed -i -E "/^KERNEL_CMDLINE\[default\]\+=/ s/\$/ $PARAMS/" /etc/default/limine
    fi
    grep -E '^KERNEL_CMDLINE' /etc/default/limine
    [[ $(grep -cE '^KERNEL_CMDLINE\[default\]' /etc/default/limine) == 1 ]] || { echo "Mais de uma linha KERNEL_CMDLINE. Abortando."; exit 1; }

    echo ">> 4/5 Sem --retain-splash (ele segurava a troca para o tty2 do ly por 5 s)"
    rm -f /etc/systemd/system/plymouth-quit.service.d/10-manter-tela.conf
    rmdir /etc/systemd/system/plymouth-quit.service.d 2>/dev/null || true
    systemctl daemon-reload

    echo ">> 5/5 Initramfs, menu e assinatura (limine-tema.sh → limine-update)"
    bash "$DIR/limine-tema.sh"
    echo
    echo "Pronto. Reinicie para ver. Se algo der errado no boot: ESC mostra o texto;"
    echo "para voltar ao boot com texto: sudo bash $0 desfazer"
}

desfazer() {
    backup /etc/mkinitcpio.conf
    backup /etc/default/limine
    sed -i -E '/^HOOKS=\(/ s/ plymouth\b//' /etc/mkinitcpio.conf
    sed -i -E "/^KERNEL_CMDLINE\[default\]\+=/ s/ $PARAMS//" /etc/default/limine
    systemctl daemon-reload
    grep -E '^HOOKS=|^KERNEL_CMDLINE' /etc/mkinitcpio.conf /etc/default/limine
    bash "$DIR/limine-tema.sh"
    echo "Boot com texto de volta (o pacote plymouth continua instalado; remova com: sudo pacman -Rns plymouth)."
}

case "${1:-aplicar}" in
    aplicar) aplicar ;;
    desfazer) desfazer ;;
    *) echo "uso: sudo bash $0 [aplicar|desfazer]"; exit 1 ;;
esac
