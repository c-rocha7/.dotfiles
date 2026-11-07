#!/usr/bin/env bash
# Diagnóstico do tempo do carregador (Limine). SOMENTE LEITURA: não altera nada.
#   sudo bash ~/.dotfiles/install/diagnostico-boot.sh
#
# O "loader" do systemd-analyze estava em ~16 s. Este script mostra o que o Limine carrega e
# confere a cada boot: tamanho do kernel/initramfs (com ENABLE_VERIFICATION o Limine calcula o
# hash deles), imagem de fundo do menu, quantidade de entradas (snapshots) e o timeout.
set -u
[ "$(id -u)" -eq 0 ] || { echo "Rode com sudo: sudo bash $0"; exit 1; }

conf=/boot/limine.conf
echo "== Tempo do último boot =="
systemd-analyze 2>/dev/null | head -1
echo

echo "== Kernel e initramfs (o Limine lê e confere o hash de cada um) =="
find /boot -maxdepth 3 -type f \( -name 'vmlinuz*' -o -name 'initramfs*' -o -name '*.img' \) \
    -printf '%10s bytes  %p\n' 2>/dev/null | sort -k3 | awk '{printf "%8.1f MB  %s\n", $1/1048576, $3}'
echo

echo "== Imagens do menu (tema) =="
find /boot/limine-tema -type f -printf '%10s bytes  %p\n' 2>/dev/null | awk '{printf "%8.1f MB  %s\n", $1/1048576, $3}'
grep -iE '^\s*(wallpaper|wallpaper_style|backdrop|interface_resolution|term_font_scale|timeout|verbose|quiet|editor_enabled)\s*:' "$conf" 2>/dev/null
echo

echo "== Entradas no menu =="
printf '  entradas de boot (linhas "protocol"): %s\n' "$(grep -c 'protocol:' "$conf" 2>/dev/null)"
printf '  snapshots listados: %s\n' "$(grep -ciE '^\s*/+.*snapshot|//.*[0-9]{4}-[0-9]{2}-[0-9]{2}' "$conf" 2>/dev/null)"
printf '  tamanho do limine.conf: %s bytes\n' "$(stat -c %s "$conf" 2>/dev/null)"
echo

echo "== Configuração do limine-snapper-sync / mkinitcpio-hook =="
grep -E '^(MAX_SNAPSHOT_ENTRIES|LIMIT_USAGE_PERCENT|TIMEOUT|ENABLE_VERIFICATION|ENABLE_ENROLL_LIMINE_CONFIG|BOOT_ORDER|SNAPSHOT_FORMAT_CHOICE)' /etc/default/limine 2>/dev/null
echo

echo "== Compressão do initramfs =="
grep -E '^\s*COMPRESSION' /etc/mkinitcpio.conf /etc/mkinitcpio.conf.d/*.conf 2>/dev/null || echo "  (padrão do mkinitcpio: zstd)"
echo
echo "Pronto. Copie a saída acima e mande para o Claude."
