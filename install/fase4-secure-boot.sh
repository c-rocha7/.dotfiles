#!/usr/bin/env bash
# Fase 4: Secure Boot com Limine (chaves próprias via sbctl) + tira o "EFI fallback" do menu.
#
#   sudo bash fase4-secure-boot.sh preparar   # 1) com o Secure Boot DESLIGADO
#   (reiniciar e conferir que o boot e um snapshot funcionam)
#   (BIOS: apagar as chaves / "Reset to Setup Mode")
#   sudo bash fase4-secure-boot.sh chaves     # 2) grava as chaves no firmware
#   (BIOS: ligar o Secure Boot)
#   sudo bash fase4-secure-boot.sh status     # confere tudo
#
# Como fica:
# - EFI/limine/limine_x64.efi é ASSINADO com as chaves do sbctl e leva o hash (BLAKE2B) do
#   limine.conf gravado dentro (ENABLE_ENROLL_LIMINE_CONFIG=yes). O limine.conf tem o hash de
#   cada kernel/initramfs (ENABLE_VERIFICATION=yes). Com Secure Boot ativo o Limine desliga o
#   editor do menu (tecla E) e o UEFI Shell, e trava se algum hash não bater.
# - Cada mudança no menu (kernel novo, snapshot novo) passa pelos ganchos do limine-entry-tool:
#   10-limine-reset-enroll (antes) e 90-limine-enroll-config (depois: grava o hash e assina).
# - 95-limine-fallback-assinado copia o Limine assinado para EFI/BOOT/BOOTX64.EFI (reserva).
# - Kernel e initramfs NÃO são assinados (protocol: linux): o Limine confere pelo hash.
#
# Desfazer: BIOS → Secure Boot desligado; em /etc/default/limine, ENABLE_ENROLL_LIMINE_CONFIG=no
#           e depois "sudo limine-update". Backups em /var/backups/fase4-*.
# Se o boot travar com "CHECKSUM MISMATCH FOR CONFIG FILE": BIOS → Secure Boot desligado; se ainda
#   travar, pelo pendrive do Arch monte a ESP e restaure o Limine sem hash:
#   tar -xf <esp>/EFI/limine/limine_x64.bak -C <esp>/EFI/limine   (e depois rode "limine-update").

set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "Rode com sudo."; exit 1; }

DOTFILES_SYSTEM="$(dirname "$(readlink -f "$0")")/../system"
EFIVARS=/sys/firmware/efi/efivars
GUID=8be4df61-93ca-11d2-aa0d-00e098032b8c
MAIN=/boot/EFI/limine/limine_x64.efi
FALLBACK=/boot/EFI/BOOT/BOOTX64.EFI
CONF=/boot/limine.conf
DEFAULTS=/etc/default/limine
HOOK=/etc/boot/hooks/post.d/95-limine-fallback-assinado
KEYS_BACKUP=/home/.sbctl-backup

efivar() { od -An -t u1 -j4 -N1 "$EFIVARS/$1-$GUID" 2>/dev/null | tr -d ' '; }
sb_keys_created() { [[ $(sbctl setup --print-state --json 2>/dev/null) == *'"installed": true'* ]]; }

# Define (ou troca) uma opção VAR=valor no /etc/default/limine.
set_default() {
    local var=$1 val=$2 comment=$3
    if grep -qE "^#?${var}=" "$DEFAULTS"; then
        sed -i -E "s|^#?${var}=.*|${var}=${val}|" "$DEFAULTS"
    else
        printf '\n# %s\n%s=%s\n' "$comment" "$var" "$val" >> "$DEFAULTS"
    fi
}

enrolled_ok() {
    local h; h=$(b2sum "$CONF" | awk '{print $1}')
    grep -qa "$h" "$1"
}

status() {
    echo "----- Firmware -----"
    echo "SecureBoot: $(efivar SecureBoot) (1 = ligado)   SetupMode: $(efivar SetupMode) (1 = pronto para gravar chaves)"
    echo "----- sbctl -----"
    sbctl status || true
    sbctl verify 2>/dev/null | grep -iE 'limine|bootx64' || true
    echo "----- Hash do limine.conf gravado no Limine -----"
    for f in "$MAIN" "$FALLBACK"; do
        if enrolled_ok "$f"; then echo "  ok  $f"; else echo "  !!  $f (hash não confere)"; fi
    done
    echo "----- Menu (entradas do topo) -----"
    grep -E '^/' "$CONF"
}

preparar() {
    echo ">> 1/7 Conferindo"
    [[ -d $EFIVARS ]] || { echo "Não é boot UEFI. Abortando."; exit 1; }
    command -v sbctl >/dev/null || { echo "Instale o sbctl. Abortando."; exit 1; }
    grep -q '^ENABLE_VERIFICATION=yes' "$DEFAULTS" || { echo "ENABLE_VERIFICATION=yes não está em $DEFAULTS. Abortando."; exit 1; }
    [[ -L /etc/boot/hooks/pre.d/10-limine-reset-enroll && -L /etc/boot/hooks/post.d/90-limine-enroll-config ]] \
        || { echo "Ganchos de enroll do limine-entry-tool não encontrados. Abortando."; exit 1; }
    [[ -f "$DOTFILES_SYSTEM/etc/boot/hooks/post.d/95-limine-fallback-assinado" ]] \
        || { echo "Gancho 95-limine-fallback-assinado não encontrado no ~/.dotfiles/system. Abortando."; exit 1; }
    [[ $(efivar SecureBoot) == 1 ]] && { echo "O Secure Boot já está ligado. Abortando."; exit 1; }

    echo ">> 2/7 Backup (limine.conf, /etc/default/limine, pasta EFI)"
    local stamp; stamp=$(date +%Y%m%d-%H%M%S)
    mkdir -p /var/backups
    cp -a "$CONF" "/var/backups/fase4-limine.conf-$stamp"
    cp -a "$DEFAULTS" "/var/backups/fase4-default-limine-$stamp"
    tar -cf "/var/backups/fase4-EFI-$stamp.tar" -C /boot EFI

    echo ">> 3/7 Chaves do Secure Boot (sbctl)"
    if sb_keys_created; then
        echo "   chaves já existem"
    else
        sbctl create-keys
    fi
    # Cópia das chaves fora do subvolume @ (restaurar um snapshot antigo do / não as perde).
    install -d -m 700 "$KEYS_BACKUP"
    tar -cf "$KEYS_BACKUP/sbctl-keys.tar" -C /var/lib sbctl
    chmod 600 "$KEYS_BACKUP/sbctl-keys.tar"
    echo "   cópia das chaves: $KEYS_BACKUP/sbctl-keys.tar (só root)"

    echo ">> 4/7 Tirando o 'EFI fallback' do menu (o arquivo fica)"
    if grep -q '^/EFI fallback' "$CONF"; then
        limine-entry-tool --remove-efi-path "$FALLBACK" --keep-files --quiet --no-hooks
    fi

    echo ">> 5/7 Ligando o hash do limine.conf no Limine ($DEFAULTS)"
    set_default ENABLE_ENROLL_LIMINE_CONFIG yes "Secure Boot: grava o hash do limine.conf no Limine (fase4-secure-boot.sh)"
    set_default ENABLE_LIMINE_FALLBACK no "Reserva EFI/BOOT/BOOTX64.EFI mantida assinada pelo gancho 95-limine-fallback-assinado"

    echo ">> 6/7 Gancho da reserva assinada"
    install -D -m 755 "$DOTFILES_SYSTEM/etc/boot/hooks/post.d/95-limine-fallback-assinado" "$HOOK"

    echo ">> 7/7 Regenerando o menu, gravando o hash e assinando (limine-update)"
    limine-update

    echo
    status
    echo
    echo "Próximo passo: reinicie e confira o boot normal e um snapshot do menu."
    echo "Depois: BIOS → Secure Boot → apagar as chaves (Setup Mode) e rode: sudo bash $0 chaves"
}

chaves() {
    sb_keys_created || { echo "Rode 'preparar' antes. Abortando."; exit 1; }
    if [[ $(efivar SetupMode) != 1 ]]; then
        echo "O firmware não está em Setup Mode."
        echo "Na BIOS: Security → Secure Boot → Key Management → 'Delete All Secure Boot Variables'"
        echo "(ou 'Reset to Setup Mode' / 'Clear Secure Boot Keys'), salve, inicie o Linux e rode de novo."
        exit 1
    fi
    enrolled_ok "$MAIN" || { echo "O hash do limine.conf não confere no Limine. Rode 'limine-update'. Abortando."; exit 1; }
    sbctl verify 2>/dev/null | grep -q "limine_x64.efi is signed" || { echo "limine_x64.efi não está assinado. Abortando."; exit 1; }

    echo ">> Gravando as chaves no firmware (as suas + as da Microsoft, para firmware de placas e pendrives)"
    sbctl enroll-keys --microsoft
    echo
    status
    echo
    echo "Próximo passo: reinicie, entre na BIOS e LIGUE o Secure Boot. Depois rode: sudo bash $0 status"
}

case "${1:-}" in
    preparar) preparar ;;
    chaves) chaves ;;
    status) status ;;
    *) echo "uso: sudo bash $0 preparar|chaves|status"; exit 1 ;;
esac
