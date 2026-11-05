#!/usr/bin/env bash
# Copia as configurações do sistema (/etc) para ~/.dotfiles/system/, com o mesmo caminho.
# São CÓPIAS (não links): o /etc não pode depender do /home.
#
# Rodar com:  sudo bash ~/.dotfiles/system/sync.sh
# Rode de novo sempre que mudar algum destes arquivos, antes de commitar.

set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "Rode com sudo."; exit 1; }

DEST="$(dirname "$(readlink -f "$0")")"
OWNER=7aauac

FILES=(
    # Boot: Limine + snapshots, initramfs
    /etc/default/limine
    /etc/mkinitcpio.conf
    # Secure Boot: mantém a reserva EFI/BOOT/BOOTX64.EFI assinada (install/fase4-secure-boot.sh)
    /etc/boot/hooks/post.d/95-limine-fallback-assinado
    # Discos, swap em RAM
    /etc/fstab
    /etc/systemd/zram-generator.conf
    # Pacman (multilib, Chaotic-AUR)
    /etc/pacman.conf
    /etc/pacman.d/chaotic-mirrorlist
    # Snapper (snapshots do /)
    /etc/snapper/configs/root
    /etc/snapper/configs/home
    # Idioma, teclado do console, nome da máquina
    /etc/locale.gen
    /etc/locale.conf
    /etc/vconsole.conf
    # Tela de login ly (Catppuccin, pt_BR completo; install/ly.sh)
    /etc/ly/config.ini
    /etc/ly/startup.sh
    /etc/ly/lang/ptbr.ini
    /etc/ly/catppuccin.dur
    /etc/kmscon/kmscon.conf
    /etc/systemd/system/ly-kmsconvt@.service.d/10-fonte-sistema.conf
    /etc/hostname
    /etc/hosts
    # sudo (drop-ins; nunca editar /etc/sudoers direto)
    /etc/sudoers.d/10-wheel
    /etc/sudoers.d/20-pwfeedback
    # Nix: serviço copiado para subir com o /nix em subvolume próprio
    /etc/nix/nix.conf
    /etc/systemd/system/nix-daemon.service
    /etc/systemd/system/nix-daemon.socket
    # earlyoom (evita travar sem memória; install/ajustes-sistema.sh)
    /etc/default/earlyoom
    # Saúde do SSD (smartd + aviso na ilha; install/ssd-saude.sh)
    /etc/smartd.conf
    /etc/smartmontools/smartd-notificar.sh
    # plocate: pastas fora da indexação (install/plocate.sh)
    /etc/updatedb.conf
    # Rede: DNS criptografado (systemd-resolved), nomes .local/impressoras (install/rede-impressora.sh)
    /etc/systemd/resolved.conf.d/10-dns-privado.conf
    /etc/NetworkManager/conf.d/dns.conf
    /etc/nsswitch.conf
    # Firewall (ufw)
    /etc/ufw/user.rules
    /etc/ufw/user6.rules
)

copied=0
for f in "${FILES[@]}"; do
    if [[ -f "$f" ]]; then
        mkdir -p "$DEST$(dirname "$f")"
        cp "$f" "$DEST$f"
        copied=$((copied + 1))
        echo "  ok  $f"
    else
        echo "  --  $f (não existe, pulado)"
    fi
done

# Arquivos do sudoers.d e do snapper vêm com permissão só do root: deixa legível para o git.
chown -R "$OWNER:$OWNER" "$DEST/etc"
find "$DEST/etc" -type f -exec chmod 644 {} +
chmod 755 "$DEST/etc/boot/hooks/post.d/"* "$DEST/etc/smartmontools/"*.sh "$DEST/etc/ly/startup.sh" 2>/dev/null || true

echo
echo "$copied arquivos copiados para $DEST/etc"
