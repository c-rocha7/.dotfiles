#!/usr/bin/env bash
# Fase 1: move /nix e /var/lib/docker para subvolumes próprios (@nix, @docker)
# e cria @snapshots (montado na fase 2, junto com o snapper).
# Motivo: restaurar um snapshot do @ não pode "voltar no tempo" o Nix/Docker, e os
# snapshots não devem segurar GBs de pacotes do Nix e camadas do Docker.
#
# Rodar com:  sudo bash fase1-subvolumes.sh
#
# Não apaga nada: os dados antigos ficam em /nix.old e /var/lib/docker.old.
# Depois de reiniciar e conferir:  sudo rm -rf /nix.old /var/lib/docker.old

set -euo pipefail

UUID=61b69d0d-6939-4d01-9bfd-a87c1bf4d558 # UUID da partição Btrfs (blkid)
OPTS="rw,noatime,compress=zstd:3,ssd,discard=async,space_cache=v2"
TOP=/mnt/btrfs-top

[[ $EUID -eq 0 ]] || { echo "Rode com sudo."; exit 1; }

echo ">> 1/9 Conferindo o estado"
mountpoint -q /nix && { echo "/nix já é um ponto de montagem. Nada a fazer."; exit 1; }
[[ -e /nix.old || -e /var/lib/docker.old ]] && { echo "/nix.old ou /var/lib/docker.old já existe. Abortando."; exit 1; }

echo ">> 2/9 Backup do fstab"
BACKUP=/etc/fstab.bak-$(date +%Y%m%d-%H%M%S)
cp -a /etc/fstab "$BACKUP"
echo "   $BACKUP"

echo ">> 3/9 Parando Docker e Nix"
systemctl stop docker.socket docker.service containerd.service || true
systemctl stop nix-daemon.socket nix-daemon.service || true

echo ">> 4/9 Criando os subvolumes @nix, @docker e @snapshots"
mkdir -p "$TOP"
mount -o subvolid=5 "UUID=$UUID" "$TOP"
for sv in @nix @docker @snapshots; do
    if [[ -e "$TOP/$sv" ]]; then
        echo "   $sv já existe, mantendo"
    else
        btrfs subvolume create "$TOP/$sv"
    fi
done

echo ">> 5/9 Copiando os dados (reflink: instantâneo, sem duplicar espaço)"
cp -a --reflink=always /nix/. "$TOP/@nix/"
[[ -d /var/lib/docker ]] && cp -a --reflink=always /var/lib/docker/. "$TOP/@docker/"
umount "$TOP"
rmdir "$TOP"

echo ">> 6/9 Guardando as pastas antigas e criando os pontos de montagem"
mv /nix /nix.old
mkdir /nix
[[ -d /var/lib/docker ]] && mv /var/lib/docker /var/lib/docker.old
mkdir -m 710 /var/lib/docker

echo ">> 7/9 Adicionando ao fstab e montando"
cat >> /etc/fstab <<EOF

# Subvolumes fora do @ (não entram nos snapshots do sistema)
UUID=$UUID	/nix      	btrfs     	$OPTS,subvol=/@nix	0 0
UUID=$UUID	/var/lib/docker	btrfs     	$OPTS,subvol=/@docker	0 0
EOF
systemctl daemon-reload
mount /nix
mount /var/lib/docker
findmnt /nix
findmnt /var/lib/docker

echo ">> 8/9 Serviço do Nix sem depender de links para dentro do /nix"
# O instalador do Nix cria links em /etc/systemd/system apontando para /nix. No boot o
# systemd lê os serviços ANTES de montar o /nix, então o nix-daemon não subiria.
# Copiamos os arquivos e chamamos o daemon pelo perfil padrão (não por uma versão fixa).
cp --remove-destination /nix/var/nix/profiles/default/lib/systemd/system/nix-daemon.{service,socket} /etc/systemd/system/
sed -i 's|@/nix/store/[^ ]*/bin/nix-daemon|@/nix/var/nix/profiles/default/bin/nix-daemon|' /etc/systemd/system/nix-daemon.service
ln -sf /etc/systemd/system/nix-daemon.socket /etc/systemd/system/sockets.target.wants/nix-daemon.socket
systemctl daemon-reload

echo ">> 9/9 Religando Nix e Docker"
systemctl start nix-daemon.socket
systemctl start docker.socket docker.service || true

echo
echo "Pronto. Reinicie e confira: findmnt /nix ; findmnt /var/lib/docker ; nix store info"
echo "Depois:  sudo rm -rf /nix.old /var/lib/docker.old"
echo
echo "Para desfazer (antes de apagar os .old):"
echo "  sudo systemctl stop docker.socket docker.service containerd.service nix-daemon.socket nix-daemon.service"
echo "  sudo umount /nix /var/lib/docker"
echo "  sudo cp $BACKUP /etc/fstab && sudo systemctl daemon-reload"
echo "  sudo rmdir /nix /var/lib/docker && sudo mv /nix.old /nix && sudo mv /var/lib/docker.old /var/lib/docker"
echo "  sudo systemctl start nix-daemon.socket docker.socket docker.service"
