#!/usr/bin/env bash
# Initramfs menor = boot mais rápido no Limine.
#   sudo bash ~/.dotfiles/install/initramfs-menor.sh            aplica
#   sudo bash ~/.dotfiles/install/initramfs-menor.sh desfazer   volta ao backup
#
# Por quê: o initramfs tinha 53,5 MB; 29 MB eram firmware de TODAS as GPUs AMD (o hook "kms" coloca
# todo firmware que o amdgpu pode pedir; esta GPU, Renoir/green_sardine, usa 11 de 687 arquivos).
# Com o Secure Boot, o Limine lê o kernel + initramfs pela BIOS e confere o hash a cada boot
# (o "loader" do systemd-analyze estava em ~16 s).
#
# O que muda:
#   - tira o hook "kms": o amdgpu carrega do disco logo depois (com todo o firmware) e o Plymouth
#     começa na tela que a BIOS já deixou pronta (simpledrm). Pode haver uma piscada quando o
#     amdgpu assume a tela.
#   - compressão zstd -19 (multithread): ~3 MB a menos; gerar o initramfs demora um pouco mais.
#   Teste sem mexer no sistema: ~53,5 MB → ~16,4 MB.
#
# Regenera pelo limine-update (NÃO mkinitcpio -P): ele recalcula os hashes do limine.conf e os
# ganchos do Secure Boot assinam/gravam de novo.
set -euo pipefail
[ "$(id -u)" -eq 0 ] || { echo "Rode com sudo: sudo bash $0 ${1:-}"; exit 1; }

CONF=/etc/mkinitcpio.conf
BACKUP=/etc/mkinitcpio.conf.antes-initramfs-menor
INITRAMFS=$(find /boot -path '*/linux-zen/initramfs' -type f | head -1)
tamanho() { [ -n "$INITRAMFS" ] && du -m "$INITRAMFS" | cut -f1 || echo "?"; }

regenerar() {
    echo "==> Regenerando kernel/initramfs pelo limine-update (pode levar ~1 min)..."
    limine-update
    echo "==> Conferindo o Secure Boot..."
    local saida
    saida=$(bash /home/7aauac/.dotfiles/install/fase4-secure-boot.sh status 2>&1)
    echo "$saida" | sed -n '/Hash do limine.conf/,/Menu/p' | grep -v Menu
    if echo "$saida" | grep -q '!!'; then
        echo "!! O hash do limine.conf não confere. NÃO reinicie: rode 'sudo bash $0 desfazer' e me chame."
        exit 1
    fi
    echo "   Secure Boot ok."
}

if [ "${1:-}" = desfazer ]; then
    [ -f "$BACKUP" ] || { echo "Backup não encontrado: $BACKUP"; exit 1; }
    cp -a "$BACKUP" "$CONF"
    echo "==> $CONF restaurado do backup."
    regenerar
    echo "Pronto: initramfs com $(tamanho) MB (como antes). Reinicie quando quiser."
    exit 0
fi

echo "==> Initramfs atual: $(tamanho) MB ($INITRAMFS)"
grep -qE '^HOOKS=.*\bkms\b' "$CONF" || echo "   (o hook kms já não está no HOOKS)"

[ -f "$BACKUP" ] || cp -a "$CONF" "$BACKUP"
echo "==> Backup: $BACKUP"

# HOOKS sem "kms"
sed -i -E '/^HOOKS=/ s/ kms\b//' "$CONF"
# Compressão zstd -19 multithread (substitui uma linha COMPRESSION_OPTIONS ativa, se houver)
if grep -qE '^COMPRESSION_OPTIONS=' "$CONF"; then
    sed -i -E 's/^COMPRESSION_OPTIONS=.*/COMPRESSION_OPTIONS=(-19 -T0)/' "$CONF"
else
    printf '\n# Initramfs menor (install/initramfs-menor.sh)\nCOMPRESSION_OPTIONS=(-19 -T0)\n' >> "$CONF"
fi
echo "==> Nova configuração:"
grep -E '^(HOOKS|COMPRESSION_OPTIONS)=' "$CONF"

regenerar
echo
echo "Pronto: initramfs com $(tamanho) MB (antes: ~54 MB)."
echo "Reinicie e confira com: systemd-analyze   (o 'loader' estava em ~16 s)"
echo "Se algo ficar estranho no boot: sudo bash $0 desfazer"
