#!/usr/bin/env bash
# Limita os snapshots do snapper para o disco não crescer sem controle, e limpa o cache do pacman.
#
#   / (config "root"):     só os do pacman (snap-pac), as 5 últimas atualizações
#                          (5 "pre" + 5 "post" = 10; o menu do Limine mostra os 5 "pre").
#                          Sem snapshot por hora (o pacman já registra toda mudança no sistema)
#                          e sem os "importantes" (os 2 "Base" da instalação somem).
#   /home (config "home"): de hora em hora, guarda 2 por hora + 3 por dia (5 no total).
#   Cache do pacman:       paccache -rk1 (só a versão instalada) e -ruk0 (pacotes já removidos).
#
# Rodar com:            sudo bash ~/.dotfiles/install/limite-snapshots.sh
# Desfazer os limites:  sudo bash ~/.dotfiles/install/limite-snapshots.sh desfazer
#   (volta as configs do backup mais recente; snapshots já apagados não voltam)
# Depois: sudo bash ~/.dotfiles/system/sync.sh   (copia as configs novas para o repositório)

set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "Rode com sudo."; exit 1; }

CFG=/etc/snapper/configs
STAMP=$(date +%Y%m%d-%H%M%S)

if [[ ${1:-} == desfazer ]]; then
    for c in root home; do
        bak=$(ls -1t "$CFG/$c".bak-limite-* 2>/dev/null | head -1 || true)
        [[ -n $bak ]] || { echo "Sem backup de $c."; continue; }
        cp -a "$bak" "$CFG/$c"
        echo "Restaurado $CFG/$c de $bak"
    done
    exit 0
fi

usado() { btrfs filesystem usage -b / 2>/dev/null | awk '/^ *Used:/ {printf "%.1f GiB\n", $2/1073741824}'; }

echo ">> 1/5 Conferindo"
for c in root home; do
    [[ -f $CFG/$c ]] || { echo "Config $CFG/$c não existe. Abortando."; exit 1; }
done
ANTES=$(usado)
echo "   Usado agora: $ANTES"

echo ">> 2/5 Backup das configs (só na primeira vez: o 'desfazer' volta a config de antes do script)"
for c in root home; do
    old=$(ls -1 "$CFG/$c".bak-limite-* 2>/dev/null | head -1 || true)
    if [[ -n $old ]]; then
        echo "   já existe: $old"
    else
        cp -a "$CFG/$c" "$CFG/$c.bak-limite-$STAMP"
        echo "   $CFG/$c.bak-limite-$STAMP"
    fi
done

echo ">> 3/5 Novos limites"
snapper -c root set-config \
    NUMBER_CLEANUP=yes NUMBER_LIMIT=10 NUMBER_LIMIT_IMPORTANT=0 \
    TIMELINE_CREATE=no TIMELINE_CLEANUP=yes \
    TIMELINE_LIMIT_HOURLY=0 TIMELINE_LIMIT_DAILY=0 TIMELINE_LIMIT_WEEKLY=0 \
    TIMELINE_LIMIT_MONTHLY=0 TIMELINE_LIMIT_QUARTERLY=0 TIMELINE_LIMIT_YEARLY=0
snapper -c home set-config \
    NUMBER_CLEANUP=yes NUMBER_LIMIT=0 NUMBER_LIMIT_IMPORTANT=0 \
    TIMELINE_CREATE=yes TIMELINE_CLEANUP=yes \
    TIMELINE_LIMIT_HOURLY=2 TIMELINE_LIMIT_DAILY=3 TIMELINE_LIMIT_WEEKLY=0 \
    TIMELINE_LIMIT_MONTHLY=0 TIMELINE_LIMIT_QUARTERLY=0 TIMELINE_LIMIT_YEARLY=0
grep -E '^(NUMBER_LIMIT|NUMBER_LIMIT_IMPORTANT|TIMELINE_CREATE|TIMELINE_LIMIT_(HOURLY|DAILY|WEEKLY|MONTHLY))=' \
    "$CFG/root" "$CFG/home" | sed 's/^/   /'

echo ">> 4/5 Limpando os snapshots que passaram do limite"
# A cada snapshot apagado, o limine-snapper-watcher roda o limine-snapper-sync (menu do Limine +
# ganchos do Secure Boot), que trava a config por um instante: "A configuração está bloqueada".
# Então tenta de novo até concluir.
limpar() {
    local c=$1 alg=$2 i
    for i in $(seq 1 30); do
        snapper -c "$c" cleanup "$alg" 2>/dev/null && { echo "   $c/$alg: ok"; return 0; }
        sleep 3
    done
    echo "   $c/$alg: config continua bloqueada; o snapper-cleanup.timer (de hora em hora) termina sozinho."
}
for c in root home; do
    for alg in number timeline empty-pre-post; do
        limpar "$c" "$alg"
    done
done
echo "   Restaram:"
echo "   / (root):"; snapper -c root list --columns number,type,date,description | sed 's/^/     /'
echo "   /home:";    snapper -c home list --columns number,type,date,description | sed 's/^/     /'

echo ">> 5/5 Cache do pacman"
du -sh /var/cache/pacman/pkg | sed 's/^/   Antes: /'
paccache -rk1
paccache -ruk0
du -sh /var/cache/pacman/pkg | sed 's/^/   Depois: /'

echo
echo "Esperando o Btrfs liberar o espaço dos snapshots apagados..."
btrfs subvolume sync / >/dev/null 2>&1 || true
echo "Usado antes: $ANTES   depois: $(usado)"
echo
echo "Conferir o Secure Boot/menu: sudo bash ~/.dotfiles/install/fase4-secure-boot.sh status"
echo "Copiar as configs para o repositório: sudo bash ~/.dotfiles/system/sync.sh"
