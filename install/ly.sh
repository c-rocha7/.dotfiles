#!/usr/bin/env bash
# Tela de login (ly) com o visual do sistema: Catppuccin Mocha, desenho de fundo (montanhas e
# estrelas, install/gen_ly_dur.py), relógio grande, bateria, pt_BR completo.
#
#   sudo bash ly.sh                 1) aplica a config e abre um ly de TESTE no tty3 (console comum,
#                                      fonte Terminus 24, que também vale para os TTYs)
#   sudo bash ly.sh kmscon-teste    2) instala o kmscon (fonte FiraCode 16 px = 12 pt do sistema,
#                                      paleta Catppuccin) e abre o ly com ele no tty3, para ver
#   sudo bash ly.sh kmscon-ativar   3) passa o login de verdade (tty2) para o ly com kmscon (vale no
#                                      próximo boot)
#   sudo bash ly.sh kmscon-desfazer    volta o tty2 para o ly comum
#   sudo bash ly.sh atualizar          só reinstala os arquivos do ly (config, cores, tradução, desenho)
#                                      e abre o teste no tty3 do mesmo jeito que o login atual
#   sudo bash ly.sh parar-teste        fecha o ly de teste do tty3
#
# Ver o teste: Ctrl+Alt+F3. Voltar para a sessão: Ctrl+Alt+F2.
# O ly do tty2 NUNCA é reiniciado aqui: a sessão atual depende dele.
# Se o login com kmscon falhar no boot: Ctrl+Alt+F3 → login em texto → sudo bash ~/.dotfiles/install/ly.sh kmscon-desfazer
# Desfazer tudo: restaure /var/backups/ly-* e rode sudo limine-update

set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "Rode com sudo."; exit 1; }
SRC="$(dirname "$(readlink -f "$0")")/../system/etc"
STAMP=$(date +%Y%m%d-%H%M%S)
FONT=ter-v24b

stop_tests() {
    systemctl stop ly@tty3 ly-kmsconvt@tty3 2>/dev/null || true
}

aplicar() {
    echo ">> 1/4 Fonte Terminus (TTYs)"
    pacman -S --needed terminus-font
    [[ -f /usr/share/kbd/consolefonts/$FONT.psf.gz ]] || { echo "Fonte $FONT não encontrada. Abortando."; exit 1; }

    echo ">> 2/4 Config, cores, desenho e tradução do ly"
    mkdir -p /var/backups
    [[ -f /var/backups/ly-config.ini-original ]] || cp -a /etc/ly/config.ini /var/backups/ly-config.ini-original
    [[ -f /var/backups/ly-startup.sh-original ]] || cp -a /etc/ly/startup.sh /var/backups/ly-startup.sh-original
    install -m 644 "$SRC/ly/config.ini" /etc/ly/config.ini
    install -m 755 "$SRC/ly/startup.sh" /etc/ly/startup.sh
    install -m 644 "$SRC/ly/lang/ptbr.ini" /etc/ly/lang/ptbr.ini
    install -m 644 "$SRC/ly/catppuccin.dur" /etc/ly/catppuccin.dur
    install -d -m 755 /etc/ly/xsessions   # vazia: sem X11 instalado (ver config.ini)

    echo ">> 3/4 Fonte do console ($FONT) e initramfs"
    if ! grep -q "^FONT=$FONT$" /etc/vconsole.conf; then
        cp -a /etc/vconsole.conf "/var/backups/ly-vconsole.conf-$STAMP"
        if grep -q '^FONT=' /etc/vconsole.conf; then
            sed -i "s/^FONT=.*/FONT=$FONT/" /etc/vconsole.conf
        else
            echo "FONT=$FONT" >> /etc/vconsole.conf
        fi
        limine-update
    fi
    cat /etc/vconsole.conf

    echo ">> 4/4 ly de teste no tty3 (console comum)"
    stop_tests
    setfont -C /dev/tty3 "$FONT" 2>/dev/null || true
    systemctl start ly@tty3
    sleep 1
    systemctl is-active ly@tty3
    echo
    echo "Veja com Ctrl+Alt+F3 e volte com Ctrl+Alt+F2."
    echo "Próximo: sudo bash $0 kmscon-teste   (fonte FiraCode igual à do sistema)"
}

# Drop-ins do ly com kmscon: fonte do sistema (todas as instâncias) e troca para o tty2 no boot.
install_kmscon_dropins() {
    install -D -m 644 "$SRC/systemd/system/ly-kmsconvt@.service.d/10-fonte-sistema.conf" \
        "/etc/systemd/system/ly-kmsconvt@.service.d/10-fonte-sistema.conf"
    install -D -m 644 "$SRC/systemd/system/ly-kmsconvt@tty2.service.d/20-mostrar-tty2.conf" \
        "/etc/systemd/system/ly-kmsconvt@tty2.service.d/20-mostrar-tty2.conf"
    systemctl daemon-reload
}

kmscon_teste() {
    echo ">> 1/3 kmscon"
    pacman -S --needed kmscon inotify-tools
    kmscon --help 2>&1 | grep -q -- '--configdir' || { echo "Este kmscon não tem --configdir. Abortando."; exit 1; }

    echo ">> 2/3 Fonte e paleta (/etc/kmscon/kmscon.conf) e serviço do ly com kmscon"
    install -D -m 644 "$SRC/kmscon/kmscon.conf" /etc/kmscon/kmscon.conf
    install_kmscon_dropins
    [[ -f /etc/ly/catppuccin.dur ]] || { echo "Rode antes: sudo bash $0"; exit 1; }
    systemctl daemon-reload

    echo ">> 3/3 ly com kmscon de teste no tty3"
    stop_tests
    systemctl start ly-kmsconvt@tty3
    sleep 2
    systemctl is-active ly-kmsconvt@tty3 || { journalctl -u ly-kmsconvt@tty3 -n 20 --no-pager; exit 1; }
    echo
    echo "Veja com Ctrl+Alt+F3 e volte com Ctrl+Alt+F2."
    echo "Se gostar: sudo bash $0 kmscon-ativar"
}

kmscon_ativar() {
    [[ -f /etc/systemd/system/ly-kmsconvt@.service.d/10-fonte-sistema.conf ]] || { echo "Rode antes: sudo bash $0 kmscon-teste"; exit 1; }
    stop_tests
    install_kmscon_dropins
    systemctl disable ly@tty2.service
    systemctl enable ly-kmsconvt@tty2.service
    echo
    echo "Pronto: no próximo boot o login (tty2) usa o ly com kmscon. NÃO foi reiniciado agora."
    echo "Se o login falhar: Ctrl+Alt+F3 → entre em modo texto → sudo bash $0 kmscon-desfazer → reinicie."
}

kmscon_desfazer() {
    systemctl disable ly-kmsconvt@tty2.service 2>/dev/null || true
    systemctl enable ly@tty2.service
    echo "tty2 de volta ao ly comum (vale no próximo boot)."
}

atualizar() {
    install -m 644 "$SRC/ly/config.ini" /etc/ly/config.ini
    install -m 755 "$SRC/ly/startup.sh" /etc/ly/startup.sh
    install -m 644 "$SRC/ly/lang/ptbr.ini" /etc/ly/lang/ptbr.ini
    install -m 644 "$SRC/ly/catppuccin.dur" /etc/ly/catppuccin.dur
    install -d -m 755 /etc/ly/xsessions   # vazia: sem X11 instalado (ver config.ini)
    echo "Arquivos do ly atualizados (o login do tty2 usa no próximo boot/logout)."
    stop_tests
    if systemctl is-enabled --quiet ly-kmsconvt@tty2 2>/dev/null; then
        systemctl start ly-kmsconvt@tty3
    else
        systemctl start ly@tty3
    fi
    sleep 2
    echo "Teste no tty3: Ctrl+Alt+F3 (voltar: Ctrl+Alt+F2). Fechar: sudo bash $0 parar-teste"
}

case "${1:-aplicar}" in
    aplicar) aplicar ;;
    kmscon-teste) kmscon_teste ;;
    kmscon-ativar) kmscon_ativar ;;
    kmscon-desfazer) kmscon_desfazer ;;
    atualizar) atualizar ;;
    parar-teste) stop_tests; echo "ly de teste do tty3 fechado." ;;
    *) echo "uso: sudo bash $0 [aplicar|atualizar|kmscon-teste|kmscon-ativar|kmscon-desfazer|parar-teste]"; exit 1 ;;
esac
