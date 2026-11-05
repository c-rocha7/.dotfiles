#!/usr/bin/env bash
# Limpeza da fase 3 (depois de testar a entrada nova e o boot por snapshot).
#
# Rodar com:  sudo bash fase3-limpeza.sh
#
# 1. tira a entrada "Arch Linux (backup manual)" do limine.conf (a nova vira a padrão)
#    e apaga o kernel/initramfs do lugar antigo (/boot/vmlinuz-linux-zen, initramfs-linux-zen.img)
# 2. apaga a entrada antiga da BIOS (\EFI\limine\BOOTX64.EFI), o arquivo e o hook antigo do pacman
# 3. esconde o item "EFI fallback" do menu (FIND_BOOTLOADERS=no)
# 4. ordem da BIOS: Limine (limine_x64.efi) primeiro, caminho padrão (EFI\BOOT\BOOTX64.EFI) como reserva

set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "Rode com sudo."; exit 1; }
STAMP=$(date +%Y%m%d-%H%M%S)

echo ">> 1/6 Conferindo o estado"
grep -q 'machine-id=' /boot/limine.conf || { echo "Entrada nova não encontrada no limine.conf. Abortando."; exit 1; }
[[ -f /boot/EFI/limine/limine_x64.efi ]] || { echo "limine_x64.efi não existe. Abortando."; exit 1; }
[[ -f /boot/EFI/BOOT/BOOTX64.EFI ]] || { echo "EFI/BOOT/BOOTX64.EFI (reserva) não existe. Abortando."; exit 1; }
new_entry=$(efibootmgr | awk 'tolower($0) ~ /limine_x64\.efi/ {sub(/^Boot/,"",$1); sub(/\*$/,"",$1); print $1; exit}')
[[ -n "$new_entry" ]] || { echo "Entrada da BIOS para limine_x64.efi não encontrada. Abortando."; exit 1; }

echo ">> 2/6 Backup do limine.conf"
cp -a /boot/limine.conf "/var/backups/limine.conf.antes-limpeza-$STAMP"

echo ">> 3/6 Tirando a entrada 'Arch Linux (backup manual)' e o kernel antigo"
# Apaga do cabeçalho "/Arch Linux (backup manual)" até antes da próxima entrada de nível 1 ("/...").
awk '
    /^\/Arch Linux \(backup manual\)$/ { skip = 1; next }
    skip && /^\// { skip = 0 }
    !skip { print }
' /boot/limine.conf > /boot/limine.conf.new
mv /boot/limine.conf.new /boot/limine.conf
rm -f /boot/vmlinuz-linux-zen /boot/initramfs-linux-zen.img /boot/limine.conf.bak-*

echo ">> 4/6 Entrada antiga da BIOS, arquivo antigo e hook antigo do pacman"
old_entry=$(efibootmgr | awk 'tolower($0) ~ /\\efi\\limine\\bootx64\.efi/ {sub(/^Boot/,"",$1); sub(/\*$/,"",$1); print $1; exit}')
if [[ -n "$old_entry" ]]; then
    efibootmgr -q -b "$old_entry" -B
    echo "   entrada Boot$old_entry removida"
fi
rm -f /boot/EFI/limine/BOOTX64.EFI
rm -f /etc/pacman.d/hooks/limine.hook

echo ">> 5/6 Escondendo o 'EFI fallback' e regenerando o menu"
grep -q '^FIND_BOOTLOADERS=' /etc/default/limine || printf '\n# Não lista outros carregadores EFI no menu (o "EFI fallback" era o próprio Limine)\nFIND_BOOTLOADERS=no\n' >> /etc/default/limine
limine-update

echo ">> 6/6 Ordem da BIOS: Limine primeiro, caminho padrão como reserva"
fallback_entry=$(efibootmgr | awk 'tolower($0) ~ /\\efi\\boot\\bootx64\.efi/ {sub(/^Boot/,"",$1); sub(/\*$/,"",$1); print $1; exit}')
others=$(efibootmgr | awk -F': ' '/^BootOrder/ {print $2}' | tr ',' '\n' | grep -v -x -e "$new_entry" -e "${fallback_entry:-NONE}" | paste -sd,)
efibootmgr -q -o "$(echo "$new_entry,${fallback_entry:+$fallback_entry,}$others" | sed 's/,$//')"

echo
echo "----- /boot/limine.conf (entradas) -----"
grep -E '^/|^\s+//[^/]|^\s+///' /boot/limine.conf
echo "----- /boot -----"
ls /boot /boot/EFI/limine
df -h /boot | tail -1
echo "----- BIOS -----"
efibootmgr
echo
echo "Pronto. Backup do limine.conf anterior: /var/backups/limine.conf.antes-limpeza-$STAMP"
echo "Backup completo do /boot de antes da fase 3: /var/backups/boot-antes-fase3-*.tar"
