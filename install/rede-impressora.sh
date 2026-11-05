#!/usr/bin/env bash
# Rede e impressão.
#
# Rodar com:  sudo bash rede-impressora.sh
#
# 1. boot ~4 s mais rápido: desliga o NetworkManager-wait-online (nada no notebook precisa da
#    rede pronta antes do login)
# 2. DNS criptografado (DNS over TLS, modo flexível) via systemd-resolved: Quad9 + Cloudflare de
#    reserva. Se depois da troca não resolver nomes, DESFAZ sozinho.
# 3. impressora de rede sem driver (CUPS + IPP Everywhere/AirPrint): avahi + nss-mdns para achar as
#    impressoras e os nomes .local; firewall libera só o mDNS (5353/udp). Painel: system-config-printer.
#
# Desfazer:
#   1. sudo systemctl enable NetworkManager-wait-online
#   2. sudo rm /etc/NetworkManager/conf.d/dns.conf /etc/systemd/resolved.conf.d/10-dns-privado.conf;
#      sudo systemctl disable --now systemd-resolved; restaure /var/backups/rede-resolv.conf-*;
#      sudo systemctl restart NetworkManager
#   3. restaure /var/backups/rede-nsswitch.conf-*; sudo ufw delete allow 5353/udp;
#      sudo systemctl disable --now cups.socket avahi-daemon

set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "Rode com sudo."; exit 1; }
SRC="$(dirname "$(readlink -f "$0")")/../system/etc"
STAMP=$(date +%Y%m%d-%H%M%S)
mkdir -p /var/backups

resolves() { getent ahosts archlinux.org >/dev/null 2>&1; }

echo ">> 1/3 Boot sem esperar a rede"
systemctl disable NetworkManager-wait-online.service 2>/dev/null || true
systemctl is-enabled NetworkManager-wait-online.service 2>/dev/null || true

echo ">> 2/3 DNS criptografado (systemd-resolved)"
if [[ $(readlink /etc/resolv.conf) == /run/systemd/resolve/stub-resolv.conf ]]; then
    echo "   resolv.conf já aponta para o systemd-resolved"
else
    cp -a /etc/resolv.conf "/var/backups/rede-resolv.conf-$STAMP"
fi
install -D -m 644 "$SRC/systemd/resolved.conf.d/10-dns-privado.conf" /etc/systemd/resolved.conf.d/10-dns-privado.conf
install -D -m 644 "$SRC/NetworkManager/conf.d/dns.conf" /etc/NetworkManager/conf.d/dns.conf
systemctl enable --now systemd-resolved
systemctl restart systemd-resolved
ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
echo "   reiniciando o NetworkManager (o Wi-Fi cai por alguns segundos)..."
systemctl restart NetworkManager
# O Wi-Fi leva alguns segundos para reconectar: testa a cada 1 s por até 40 s antes de desistir.
ok=no
for _ in $(seq 40); do
    sleep 1
    resolves && { ok=yes; break; }
done

if [[ $ok == yes ]]; then
    echo "   ok: nomes resolvendo pelo DNS criptografado"
    resolvectl status | grep -E 'Current DNS Server|DNS over TLS|Protocols' | head -4
else
    echo "   !! Não resolveu nomes: desfazendo a troca de DNS."
    rm -f /etc/NetworkManager/conf.d/dns.conf /etc/systemd/resolved.conf.d/10-dns-privado.conf
    systemctl disable --now systemd-resolved || true
    backup=$(ls -t /var/backups/rede-resolv.conf-* 2>/dev/null | head -1)
    [[ -n $backup ]] && { rm -f /etc/resolv.conf; cp -a "$backup" /etc/resolv.conf; }
    systemctl restart NetworkManager
    for _ in $(seq 40); do sleep 1; resolves && break; done
    echo "   DNS voltou ao anterior. Seguindo para a impressora."
fi

echo ">> 3/3 Impressora de rede (sem driver)"
pacman -S --needed cups nss-mdns system-config-printer
if ! grep -qE '^hosts:.*mdns_minimal' /etc/nsswitch.conf; then
    cp -a /etc/nsswitch.conf "/var/backups/rede-nsswitch.conf-$STAMP"
    sed -i -E '/^hosts:/ s/ resolve / mdns_minimal [NOTFOUND=return] resolve /' /etc/nsswitch.conf
    grep -qE '^hosts:.*mdns_minimal' /etc/nsswitch.conf || { echo "Não consegui editar o nsswitch.conf. Abortando."; exit 1; }
    resolves || { echo "Nomes pararam de resolver: restaurando o nsswitch.conf."; cp -a "/var/backups/rede-nsswitch.conf-$STAMP" /etc/nsswitch.conf; exit 1; }
fi
grep '^hosts:' /etc/nsswitch.conf
systemctl enable --now avahi-daemon.service cups.socket
systemctl start cups.service
ufw allow 5353/udp comment 'mDNS: impressoras de rede e nomes .local' >/dev/null
ufw status | grep 5353 || true

echo
echo "Impressoras encontradas na rede (pode levar alguns segundos para aparecerem):"
sleep 5
lpstat -e 2>/dev/null || true
echo
echo "Para adicionar/gerenciar: abra 'Configurar impressoras' (system-config-printer) ou http://localhost:631"
