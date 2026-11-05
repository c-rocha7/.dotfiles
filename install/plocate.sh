#!/usr/bin/env bash
# plocate: busca de arquivos instantânea ("locate nome").
#
# Rodar com:  sudo bash plocate.sh
#
# 1. instala o plocate
# 2. /etc/updatedb.conf: indexa os subvolumes (PRUNE_BIND_MOUNTS=no, senão o /home fica de fora) e
#    tira da indexação os snapshots (/.snapshots: o / repetido), o /nix (store) e o Docker
# 3. indexa agora (o plocate-updatedb.timer do pacote reindexa todo dia)
#
# Desfazer: sudo pacman -Rns plocate (o timer sai junto); restaure /var/backups/plocate-updatedb.conf-*

set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "Rode com sudo."; exit 1; }
CONF=/etc/updatedb.conf
EXTRA=(/.snapshots /nix /var/lib/docker)

echo ">> 1/3 plocate"
pacman -S --needed plocate

echo ">> 2/3 $CONF (o que entra e o que fica fora da indexação)"
[[ -f $CONF ]] || { echo "$CONF não existe. Abortando."; exit 1; }
mkdir -p /var/backups
cp -a "$CONF" "/var/backups/plocate-updatedb.conf-$(date +%Y%m%d-%H%M%S)"
# Cada subvolume Btrfs montado (/home, /nix, /.snapshots...) parece um "bind mount" para o
# updatedb: com PRUNE_BIND_MOUNTS=yes o /home inteiro ficaria fora. Desliga e exclui à mão.
sed -i -E 's|^(PRUNE_BIND_MOUNTS[[:space:]]*=[[:space:]]*)"yes"|\1"no"|' "$CONF"
for dir in "${EXTRA[@]}"; do
    grep -qE "^PRUNEPATHS[[:space:]]*=[[:space:]]*\"([^\"]* )?${dir}( |\")" "$CONF" \
        || sed -i -E "s|^(PRUNEPATHS[[:space:]]*=[[:space:]]*)\"([^\"]*)\"|\1\"\2 ${dir}\"|" "$CONF"
done
# Confere se as mudanças pegaram (o formato do arquivo pode mudar entre versões).
grep -qE '^PRUNE_BIND_MOUNTS[[:space:]]*=[[:space:]]*"no"' "$CONF" || { echo "PRUNE_BIND_MOUNTS não foi alterado. Abortando."; exit 1; }
for dir in "${EXTRA[@]}"; do
    grep -qE "^PRUNEPATHS[[:space:]]*=.*[\" ]${dir}( |\")" "$CONF" || { echo "$dir não entrou no PRUNEPATHS. Abortando."; exit 1; }
done
grep -E '^PRUNE' "$CONF"

echo ">> 3/3 Indexando e ligando a atualização diária"
systemctl start plocate-updatedb.timer   # "static": o pacote já o liga sozinho
updatedb
echo
echo "Teste: locate hyprland.lua"; locate hyprland.lua
echo "Snapshots indexados (tem que ser 0): $(locate -c /.snapshots/)"
du -h /var/lib/plocate/plocate.db | cut -f1 | sed 's/^/Tamanho do índice: /'
