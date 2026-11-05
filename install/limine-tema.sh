#!/usr/bin/env bash
# Visual do menu do Limine: o mesmo desenho do ly (montanhas e estrelas Catppuccin) como wallpaper,
# paleta Catppuccin Mocha, fonte Terminus negrito 2x (igual aos TTYs), texto de marca, 3 s,
# "terse" (sem as mensagens "Loading kernel..." ao iniciar).
#
#   sudo bash limine-tema.sh            aplica (ou atualiza depois de rodar install/gen_ly_dur.py)
#   sudo bash limine-tema.sh desfazer   tira o bloco de visual (volta ao padrão, mantém timeout 3)
#
# Como funciona:
# - Arquivos em /boot/limine-tema/ (gerados por install/gen_ly_dur.py em system/boot/limine-tema/).
# - As opções ficam num bloco marcado no topo do /boot/limine.conf (antes das entradas). O
#   limine-entry-tool/limine-snapper-sync só reescrevem as entradas e mantêm esse cabeçalho.
# - Secure Boot: wallpaper e fonte levam "#<hash>" no caminho (sem hash o Limine os ignora; com hash
#   errado, trava). O limine-update regrava o hash do limine.conf no Limine e assina.
# - Confere tudo no fim; se algo falhar, restaura o backup (/var/backups/limine-tema-*).

set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "Rode com sudo."; exit 1; }
SRC="$(dirname "$(readlink -f "$0")")/../system/boot/limine-tema"
CONF=/boot/limine.conf
DEST=/boot/limine-tema
MAIN=/boot/EFI/limine/limine_x64.efi
FALLBACK=/boot/EFI/BOOT/BOOTX64.EFI
STAMP=$(date +%Y%m%d-%H%M%S)
BACKUP=/var/backups/limine-tema-limine.conf-$STAMP
BEGIN="# >>> tema (install/limine-tema.sh) >>>"
END="# <<< tema <<<"

b2() { b2sum "$1" | awk '{print $1}'; }

# Reescreve o cabeçalho (tudo antes da primeira entrada "/") com o bloco recebido em $1.
write_header() {
    BLOCK="$1" python3 -I - "$CONF" <<'PY'
import os, re, sys
path = sys.argv[1]
text = open(path, encoding="utf-8").read()
m = re.search(r"^/", text, re.M)
header, entries = (text[:m.start()], text[m.start():]) if m else (text, "")
begin, end = "# >>> tema (install/limine-tema.sh) >>>", "# <<< tema <<<"
header = re.sub(re.escape(begin) + r".*?" + re.escape(end) + r"\n?", "", header, flags=re.S)
keys = {l.split(":", 1)[0].strip() for l in os.environ["BLOCK"].splitlines() if ":" in l and not l.startswith("#")}
kept = [l for l in header.splitlines() if l.strip() and l.split(":", 1)[0].strip() not in keys]
new = os.environ["BLOCK"].rstrip("\n") + "\n" + ("\n".join(kept) + "\n" if kept else "") + "\n" + entries
open(path, "w", encoding="utf-8").write(new)
PY
    sync -f "$CONF"
}

verify() {
    local ok=yes h
    grep -qF "$BEGIN" "$CONF" || { echo "  !! bloco de visual sumiu do limine.conf"; ok=no; }
    for f in wallpaper.png terminus-8x16b.f16; do
        h=$(b2 "$DEST/$f")
        grep -q "limine-tema/$f#$h" "$CONF" || { echo "  !! hash de $f não confere"; ok=no; }
    done
    h=$(b2 "$CONF")
    grep -qa "$h" "$MAIN" || { echo "  !! hash do limine.conf não está gravado no Limine"; ok=no; }
    cmp -s "$MAIN" "$FALLBACK" || { echo "  !! reserva BOOTX64.EFI diferente do principal"; ok=no; }
    [[ $ok == yes ]]
}

restore() {
    echo ">> Restaurando o backup ($BACKUP)"
    cp -a "$BACKUP" "$CONF"
    limine-update
    exit 1
}

aplicar() {
    echo ">> 1/5 Conferindo"
    for f in wallpaper.png terminus-8x16b.f16; do
        [[ -f $SRC/$f ]] || { echo "$SRC/$f não existe (rode install/gen_ly_dur.py). Abortando."; exit 1; }
    done
    [[ $(stat -c %s "$SRC/terminus-8x16b.f16") == 4096 ]] || { echo "Fonte com tamanho errado. Abortando."; exit 1; }
    grep -q '^/' "$CONF" || { echo "$CONF sem entradas. Abortando."; exit 1; }
    mkdir -p /var/backups
    cp -a "$CONF" "$BACKUP"

    echo ">> 2/5 Copiando wallpaper e fonte para $DEST"
    install -d -m 700 "$DEST"
    install -m 600 "$SRC/wallpaper.png" "$SRC/terminus-8x16b.f16" "$DEST/"
    sync -f "$DEST/wallpaper.png"

    echo ">> 3/5 Opções de visual no topo do limine.conf"
    local wp font
    wp=$(b2 "$DEST/wallpaper.png"); font=$(b2 "$DEST/terminus-8x16b.f16")
    write_header "$BEGIN
# Catppuccin Mocha. Arquivos com hash (Secure Boot). Não edite à mão: rode install/limine-tema.sh.
timeout: 3
terse: yes
interface_resolution: 1920x1080
interface_branding: Arch Linux - vision-r15m
interface_branding_colour: CBA6F7
interface_help_colour: 7F849C
interface_help_colour_bright: 89B4FA
wallpaper: boot():/limine-tema/wallpaper.png#$wp
wallpaper_style: stretched
term_font: boot():/limine-tema/terminus-8x16b.f16#$font
term_font_size: 8x16
term_font_scale: 2x2
term_font_spacing: 0
term_palette: 1E1E2E;F38BA8;A6E3A1;F9E2AF;89B4FA;CBA6F7;94E2D5;BAC2DE
term_palette_bright: 585B70;F38BA8;A6E3A1;F9E2AF;89B4FA;F5C2E7;94E2D5;CDD6F4
term_background: A01E1E2E
term_foreground: CDD6F4
term_foreground_bright: CDD6F4
term_margin: 64
term_margin_gradient: 4
$END"
    sed -n "/$(printf '%s' "$BEGIN" | sed 's/[][\.*^$/]/\\&/g')/,/$END/p" "$CONF" | grep -vE '#[0-9a-f]{128}' | sed 's/^/   /'

    echo ">> 4/5 Regravando o hash do menu e assinando (limine-update)"
    limine-update
    verify || restore

    echo ">> 5/5 Conferindo se o visual sobrevive a uma sincronização de snapshots"
    limine-snapper-sync || true
    verify || restore
    echo
    echo "Pronto. Reinicie para ver o menu novo. Desfazer: sudo bash $0 desfazer"
}

desfazer() {
    mkdir -p /var/backups
    cp -a "$CONF" "$BACKUP"
    write_header "timeout: 3"
    limine-update
    h=$(b2 "$CONF")
    grep -qa "$h" "$MAIN" || restore
    rm -rf "$DEST"
    echo "Visual removido (menu padrão, timeout 3)."
}

case "${1:-aplicar}" in
    aplicar) aplicar ;;
    desfazer) desfazer ;;
    *) echo "uso: sudo bash $0 [aplicar|desfazer]"; exit 1 ;;
esac
