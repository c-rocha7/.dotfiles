#!/usr/bin/env bash
# Dual boot com o Windows 11 sem mexer no Arch (Limine + Secure Boot + Btrfs continuam iguais).
#
# Etapas (cada uma é independente; rode na ordem):
#   sudo bash ~/.dotfiles/install/dual-boot-windows.sh status
#       Só mostra: partições, espaço livre, TPM, Secure Boot, entradas da BIOS, ESP.
#   sudo bash ~/.dotfiles/install/dual-boot-windows.sh encolher <GiB>
#       Encolhe o Btrfs (nvme0n1p2) com o sistema rodando e deixa <GiB> NÃO alocados no fim do
#       disco para o instalador do Windows. Faz backup da tabela de partições antes.
#   (instalar o Windows no "Espaço não alocado"; ver docs/dual-boot-windows.md)
#   sudo bash ~/.dotfiles/install/dual-boot-windows.sh pos-windows
#       Depois de instalar o Windows: põe o Limine de novo em 1º na BIOS e restaura o
#       EFI/BOOT/BOOTX64.EFI (o Windows troca pelo dele).
#   sudo bash ~/.dotfiles/install/dual-boot-windows.sh limine-windows
#       Põe "Windows 11" no menu do Limine (limine-entry-tool --add-efi, protocol: efi: sem hash,
#       a BIOS confere a assinatura). Remover: ... limine-windows-remover
#   sudo bash ~/.dotfiles/install/dual-boot-windows.sh windows
#       Reinicia direto no Windows uma vez (efibootmgr --bootnext), sem mexer na ordem.
#
# Desfazer o "encolher" (só enquanto o Windows NÃO foi instalado, ou depois de apagar as
# partições dele): sudo bash ~/.dotfiles/install/dual-boot-windows.sh desfazer
# Backup da tabela de partições: /home/.dual-boot-backup/ (restaurar: sfdisk /dev/nvme0n1 < arquivo,
# a partir de um pendrive do Arch).

set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "Rode com sudo."; exit 1; }

DISCO=/dev/nvme0n1
PART=${DISCO}p2
NUM=2
ESP=/boot
BAK=/home/.dual-boot-backup
STAMP=$(date +%Y%m%d-%H%M%S)
GiB=$((1024 * 1024 * 1024))
MiB=$((1024 * 1024))

ss() { cat /sys/block/${DISCO##*/}/queue/logical_block_size; }                  # bytes por setor
part_bytes() { echo $(( $(cat /sys/block/${DISCO##*/}/${PART##*/}/size) * 512 )); }
btrfs_dev_bytes() { btrfs filesystem show --raw / | awk -v p="$PART" '$0 ~ p {for(i=1;i<=NF;i++) if($i=="size") print $(i+1)}'; }
btrfs_unalloc() { btrfs filesystem usage -b / | awk '/Device unallocated:/ {print $3}'; }
gib() { awk -v b="$1" 'BEGIN{printf "%.1f GiB", b/1073741824}'; }
ultima_part() { lsblk -nro NAME,TYPE "$DISCO" | awk '$2=="part"{n=$1} END{print n}'; }

status() {
    echo "== Partições"; lsblk -o NAME,SIZE,FSTYPE,PARTTYPENAME,LABEL "$DISCO"
    echo; echo "== Espaço não alocado no disco"; sfdisk -F "$DISCO" | sed -n '1,/^$/p;/Start/,$p'
    echo "== Btrfs: partição $(gib "$(part_bytes)"), Btrfs $(gib "$(btrfs_dev_bytes)"), livre dentro do Btrfs $(gib "$(btrfs_unalloc)")"
    echo; echo "== TPM: $(cat /sys/class/tpm/tpm0/tpm_version_major 2>/dev/null || echo ausente)"
    echo "== Secure Boot:"; sbctl status 2>/dev/null | sed 's/^/   /'
    echo; echo "== Entradas da BIOS"; efibootmgr
    echo; echo "== ESP"; df -h "$ESP" | tail -1
    [[ -d $ESP/EFI/Microsoft ]] && echo "   Windows Boot Manager presente: $ESP/EFI/Microsoft/Boot/bootmgfw.efi"
    if cmp -s "$ESP/EFI/limine/limine_x64.efi" "$ESP/EFI/BOOT/BOOTX64.EFI"; then
        echo "   EFI/BOOT/BOOTX64.EFI = Limine (ok)"
    else
        echo "   EFI/BOOT/BOOTX64.EFI NÃO é o Limine (rode a etapa pos-windows)"
    fi
}

encolher() {
    local n=${1:-}
    [[ $n =~ ^[0-9]+$ ]] && (( n >= 64 && n <= 300 )) || { echo "Uso: encolher <GiB entre 64 e 300> (ex.: encolher 150)"; exit 1; }

    echo ">> 1/6 Conferindo"
    [[ $(ultima_part) == "${PART##*/}" ]] || { echo "   ${PART} não é a última partição (já existe outra depois?). Abortando."; exit 1; }
    local ac; ac=$(cat /sys/class/power_supply/A*/online 2>/dev/null | head -1 || echo 1)
    [[ $ac == 1 ]] || { echo "   Ligue o carregador antes. Abortando."; exit 1; }
    local livre; livre=$(btrfs_unalloc)
    (( livre > (n + 30) * GiB )) || { echo "   Pouco espaço livre no Btrfs ($(gib "$livre")); precisa de ${n} GiB + 30 GiB de folga."; exit 1; }
    [[ $(btrfs_dev_bytes) == "$(part_bytes)" ]] || echo "   aviso: o Btrfs já é menor que a partição (resto de uma execução anterior?); seguindo."
    echo "   Btrfs livre: $(gib "$livre"); vai sobrar $(gib $((livre - n * GiB))) para o Arch."

    local atual novo alvo
    atual=$(part_bytes)
    novo=$(( (atual - n * GiB) / MiB * MiB ))          # nova partição, alinhada em 1 MiB
    alvo=$(( novo - GiB ))                               # Btrfs 1 GiB menor que a partição (margem)

    echo ">> 2/6 Backup da tabela de partições"
    install -d -m 700 "$BAK"
    sfdisk -d "$DISCO" > "$BAK/particoes-$STAMP.sfdisk"
    echo "   $BAK/particoes-$STAMP.sfdisk"

    echo ">> 3/6 Encolhendo o Btrfs para $(gib "$alvo") (move dados se preciso; pode levar alguns minutos)"
    btrfs filesystem resize "1:$alvo" /

    echo ">> 4/6 Encolhendo a partição para $(gib "$novo") (mesmo início, mesmo UUID)"
    echo ",$(( novo / $(ss) ))" | sfdisk -N "$NUM" --no-reread --no-tell-kernel "$DISCO"
    partx -u --nr "$NUM" "$DISCO"
    [[ $(part_bytes) == "$novo" ]] || { echo "   O kernel ainda vê o tamanho antigo. NÃO reinicie sem conferir: sfdisk -l $DISCO"; exit 1; }

    echo ">> 5/6 Ajustando o Btrfs ao tamanho exato da partição"
    btrfs filesystem resize 1:max /
    (( $(btrfs_dev_bytes) <= $(part_bytes) )) || { echo "   ERRO: Btrfs maior que a partição!"; exit 1; }

    echo ">> 6/6 Resultado"
    status | sed -n '1,/^== TPM/p' | head -n -1
    echo "Pronto. Instale o Windows no \"Espaço não alocado\" (não apague nem formate as outras partições)."
}

desfazer() {
    [[ $(ultima_part) == "${PART##*/}" ]] || { echo "Existe partição depois da ${PART} (Windows instalado?). Apague-as primeiro (no Windows ou no gparted)."; exit 1; }
    echo ">> Crescendo a partição até o fim do disco"
    sfdisk -d "$DISCO" > "$BAK/particoes-antes-desfazer-$STAMP.sfdisk" 2>/dev/null || true
    echo ",+" | sfdisk -N "$NUM" --no-reread --no-tell-kernel "$DISCO"
    partx -u --nr "$NUM" "$DISCO"
    btrfs filesystem resize 1:max /
    status | sed -n '1,/^== TPM/p' | head -n -1
}

pos_windows() {
    echo ">> 1/3 Ordem de boot: Limine primeiro"
    local limine reserva win resto
    limine=$(efibootmgr | awk '/\* Limine/ {print substr($1,5,4)}' | head -1)
    reserva=$(efibootmgr | awk '/\* UEFI OS/ {print substr($1,5,4)}' | head -1)
    win=$(efibootmgr | awk '/\* Windows Boot Manager/ {print substr($1,5,4)}' | head -1)
    [[ -n $limine ]] || { echo "   Entrada Limine não encontrada! Recrie com: efibootmgr --create --disk $DISCO --part 1 --label Limine --loader '\\EFI\\limine\\limine_x64.efi'"; exit 1; }
    [[ -n $win ]] || echo "   aviso: entrada 'Windows Boot Manager' não encontrada."
    resto=$(efibootmgr | awk -F': ' '/^BootOrder/ {print $2}' | tr ',' '\n' | grep -vxE "${limine}|${reserva:-x}|${win:-x}" | paste -sd, || true)
    efibootmgr -q -o "$(echo "$limine,${reserva},${win},${resto}" | sed 's/,,*/,/g;s/^,//;s/,$//')"
    efibootmgr | grep -E '^Boot(Order|Current)'

    echo ">> 2/3 Restaurando EFI/BOOT/BOOTX64.EFI = Limine assinado"
    cp -a "$ESP/EFI/BOOT/BOOTX64.EFI" "$BAK/BOOTX64.EFI.windows-$STAMP" 2>/dev/null || true
    /etc/boot/hooks/post.d/95-limine-fallback-assinado
    if cmp -s "$ESP/EFI/limine/limine_x64.efi" "$ESP/EFI/BOOT/BOOTX64.EFI"; then echo "   ok"; else echo "   NÃO restaurou (o Limine está assinado? sbctl verify)"; fi

    echo ">> 3/3 ESP"
    df -h "$ESP" | tail -1
    du -sh "$ESP/EFI/Microsoft" 2>/dev/null || true
}

NOME_LIMINE="Windows 11"
BOOTMGFW=$ESP/EFI/Microsoft/Boot/bootmgfw.efi
CONF=$ESP/limine.conf

limine_ok() {   # hash do limine.conf gravado no Limine + Limine assinado (mesma checagem do fase4)
    local h; h=$(b2sum "$CONF" | awk '{print $1}')
    grep -qa "$h" "$ESP/EFI/limine/limine_x64.efi" && sbctl verify 2>/dev/null | grep -q "limine_x64.efi is signed"
}

limine_windows() {
    echo ">> 1/4 Conferindo"
    [[ -f $BOOTMGFW ]] || { echo "   $BOOTMGFW não existe. Abortando."; exit 1; }
    limine_ok || { echo "   O Limine já está com problema (hash/assinatura) ANTES da mudança. Rode 'limine-update' e confira. Abortando."; exit 1; }

    echo ">> 2/4 Backup do limine.conf"
    install -d -m 700 "$BAK"
    cp -a "$CONF" "$BAK/limine.conf-$STAMP"
    echo "   $BAK/limine.conf-$STAMP"

    echo ">> 3/4 Criando a entrada \"$NOME_LIMINE\" (protocol: efi; os ganchos gravam o hash e assinam)"
    limine-entry-tool --add-efi "$NOME_LIMINE" "$BOOTMGFW" --comment "Windows Boot Manager" --priority 90 --overwrite

    echo ">> 4/4 Conferindo o resultado"
    grep -n -A6 -F "/$NOME_LIMINE" "$CONF" | sed 's/^/   /' || echo "   !! entrada não encontrada no limine.conf"
    if limine_ok; then
        echo "   ok: hash do limine.conf gravado no Limine e Limine assinado."
    else
        echo "   !! Hash/assinatura não conferem. Rodando limine-update para refazer..."
        limine-update
        limine_ok && echo "   ok depois do limine-update." || { echo "   AINDA COM ERRO: NÃO reinicie. Me mande esta saída."; exit 1; }
    fi
    /etc/boot/hooks/post.d/95-limine-fallback-assinado
    if grep -A6 -F "/$NOME_LIMINE" "$CONF" | grep -qiE 'bootmgfw\.efi#'; then
        echo "   aviso: o caminho do Windows ficou com #hash. Uma atualização do Windows que troque o"
        echo "   bootmgfw.efi vai travar ESSA entrada (o Arch continua normal). Me mande esta saída."
    fi
    echo "Pronto. Reinicie e escolha \"$NOME_LIMINE\" no menu do Limine."
}

limine_windows_remover() {
    cp -a "$CONF" "$BAK/limine.conf-$STAMP" 2>/dev/null || true
    limine-entry-tool --remove-entry "$NOME_LIMINE"
    limine_ok && echo "ok: entrada removida, Limine conferido." || { echo "Hash não confere: rodando limine-update"; limine-update; }
}

windows() {
    local win; win=$(efibootmgr | awk '/\* Windows Boot Manager/ {print substr($1,5,4)}' | head -1)
    [[ -n $win ]] || { echo "Entrada 'Windows Boot Manager' não encontrada."; exit 1; }
    efibootmgr -q -n "$win"
    echo "Reiniciando no Windows (só desta vez)..."
    systemctl reboot
}

case ${1:-status} in
    status)      status ;;
    encolher)    encolher "${2:-}" ;;
    desfazer)    desfazer ;;
    pos-windows) pos_windows ;;
    windows)     windows ;;
    limine-windows)          limine_windows ;;
    limine-windows-remover)  limine_windows_remover ;;
    *) echo "Uso: $0 status | encolher <GiB> | desfazer | pos-windows | limine-windows | limine-windows-remover | windows"; exit 1 ;;
esac
