#!/usr/bin/env bash
# Fase 3: snapshots do snapper no menu do Limine (limine-mkinitcpio-hook + limine-snapper-sync).
#
# Rodar com:  sudo bash fase3-limine-snapper.sh   (depois das fases 1 e 2)
# Depois: reiniciar, testar a entrada nova e um snapshot, e rodar fase3-limpeza.sh.
#
# Pontos importantes descobertos ao instalar:
# - o pacote roda o limine-install JÁ NA INSTALAÇÃO (binário novo + entrada na BIOS),
#   por isso /etc/default/limine é criado antes;
# - a ferramenta reescreve a entrada chamada "Arch Linux" do limine.conf: a atual é
#   renomeada para "Arch Linux (backup manual)" e fica como volta até a limpeza;
# - o pacote substitui o hook de initramfs do Arch: o kernel passa a ser gerenciado pelo
#   limine-update (kernel em /boot/<machine-id>/linux-zen/).
#
# Proteções: backup completo do /boot (em /var/backups e no /home), backups do
# mkinitcpio.conf e do limine.conf; para no primeiro erro.

set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "Rode com sudo."; exit 1; }

UUID=61b69d0d-6939-4d01-9bfd-a87c1bf4d558 # UUID da partição Btrfs (blkid)
CMDLINE="root=UUID=$UUID rw rootflags=subvol=@"
STAMP=$(date +%Y%m%d-%H%M%S)
USER_HOME=/home/7aauac

echo ">> 1/9 Conferindo o estado"
mountpoint -q /boot || { echo "/boot não está montado. Abortando."; exit 1; }
mountpoint -q /.snapshots || { echo "/.snapshots não está montado (fase 2). Abortando."; exit 1; }
[[ -f /etc/snapper/configs/root ]] || { echo "Snapper sem config 'root'. Abortando."; exit 1; }
[[ -e /etc/default/limine ]] && { echo "/etc/default/limine já existe (fase 3 já rodou?). Abortando."; exit 1; }
grep -qx '/Arch Linux' /boot/limine.conf || { echo "Entrada '/Arch Linux' não encontrada no limine.conf. Abortando."; exit 1; }
grep -q '^HOOKS=(.*systemd' /etc/mkinitcpio.conf || { echo "mkinitcpio sem hook systemd. Abortando."; exit 1; }

echo ">> 2/9 Backup do /boot e das configurações"
mkdir -p /var/backups
tar -cf "/var/backups/boot-antes-fase3-$STAMP.tar" -C / boot
cp "/var/backups/boot-antes-fase3-$STAMP.tar" "$USER_HOME/boot-antes-fase3-$STAMP.tar"
chown 7aauac:7aauac "$USER_HOME/boot-antes-fase3-$STAMP.tar"
cp -a /etc/mkinitcpio.conf "/etc/mkinitcpio.conf.bak-$STAMP"
cp -a /boot/limine.conf "/boot/limine.conf.bak-$STAMP"

echo ">> 3/9 Renomeando a entrada atual para 'Arch Linux (backup manual)'"
sed -i 's|^/Arch Linux$|/Arch Linux (backup manual)|' /boot/limine.conf

echo ">> 4/9 Criando /etc/default/limine"
cat > /etc/default/limine <<EOF
# Configuração do limine-entry-tool (limine-mkinitcpio-hook) e do limine-snapper-sync.
# Depois de mudar: sudo limine-update

### Boot
ESP_PATH="/boot"
KERNEL_CMDLINE[default]+=$CMDLINE
ENABLE_VERIFICATION=yes
BOOT_ORDER="*, *fallback, Snapshots"

### Snapshots no menu (limine-snapper-sync)
SNAPPER_CONFIG_NAME="root"
ROOT_SUBVOLUME_PATH="/@"
ROOT_SNAPSHOTS_PATH="/@snapshots"
# A partição de boot tem 1 GB: limita o uso e só lista os snapshots "antes" do pacman.
LIMIT_USAGE_PERCENT=80
MAX_SNAPSHOT_ENTRIES=auto
EXCLUDE_SNAPSHOT_TYPES="post"
RESTORE_METHOD=replace
SNAPSHOT_FORMAT_CHOICE=2
ENABLE_NOTIFICATION=yes
EOF

echo ">> 5/9 Hook sd-btrfs-overlayfs no initramfs (iniciar por snapshots só-leitura)"
grep -q 'sd-btrfs-overlayfs' /etc/mkinitcpio.conf || \
    sed -i -E 's/^(HOOKS=\(.*\bfilesystems\b)/\1 sd-btrfs-overlayfs/' /etc/mkinitcpio.conf
grep '^HOOKS=' /etc/mkinitcpio.conf

echo ">> 6/9 Instalando limine-mkinitcpio-hook e limine-snapper-sync (Chaotic-AUR)"
pacman -S --needed limine-mkinitcpio-hook limine-snapper-sync

echo ">> 7/9 Gerando o kernel e a entrada nova do Limine (limine-update)"
limine-update

echo ">> 8/9 Ativando o serviço e criando um snapshot para o menu"
# Sem inotify-tools o serviço encerra e o plugin do snapper faz a sincronização (normal).
systemctl enable --now limine-snapper-sync.service
snapper -c root create -c number -u important=yes -d "Fase 3: snapshots no menu do Limine"
sleep 3
limine-snapper-sync || true

echo ">> 9/9 Resultado"
cat /boot/limine.conf
df -h /boot | tail -1
efibootmgr

echo
echo "Pronto. Reinicie e escolha 'Arch Linux' > 'linux-zen' (a padrão ainda é a backup)."
echo "Teste também 'Snapshots'. Depois rode: sudo bash fase3-limpeza.sh"
echo
echo "Para desfazer antes de reiniciar:"
echo "  sudo systemctl disable --now limine-snapper-sync.service"
echo "  sudo pacman -R limine-snapper-sync limine-mkinitcpio-hook"
echo "  sudo cp /etc/mkinitcpio.conf.bak-$STAMP /etc/mkinitcpio.conf && sudo rm /etc/default/limine"
echo "  sudo rm -rf /boot/* && sudo tar -xf /var/backups/boot-antes-fase3-$STAMP.tar -C /"
