#!/usr/bin/env python3
"""Imagens próprias e temas na minitela (GRAVA A FLASH da tela — leia antes).

Usa os arquivos do pacote oficial (minitela_1.0.20_amd64.deb), extraídos SEM instalar em
~/.local/share/minitela-oficial (ver README.md):
  - Texture*.acf: 21 temas prontos (compilados pela fabricante)
  - file.zip: o projeto da interface; IDE_utils/Gen/AHMISimGenDemo_og.exe: o compilador (via Wine)

Uso:
  imagens.py temas                      lista os temas (prévias em .../gifs_imagens/N.gif)
  imagens.py tema 7                     grava o tema 7 de fábrica
  imagens.py fabrica                    grava o tema padrão de fábrica (Texture.acf)
  imagens.py compilar a.jpg [b.png c.gif]   monta a interface padrão com até 3 imagens suas
  imagens.py gravar ARQUIVO.acf         grava um .acf (ex.: o que o "compilar" gerou)

Gravação (código do app oficial, via vendor/minitela_ctl.py do projeto minitela-r15):
  - só a região de texturas (0x08100000); bootloader/calibração nunca são tocados
  - o serviço da minitela é parado durante a gravação e religado depois
  - se a tela congelar (imagem que o firmware não desenha): DESLIGUE o notebook por completo
    (não basta reiniciar), ligue e grave um tema de fábrica: imagens.py fabrica
"""

import argparse
import importlib.util
import os
import shutil
import subprocess
import sys
import time
import zipfile

HERE = os.path.dirname(os.path.abspath(__file__))
OFICIAL = os.path.expanduser("~/.local/share/minitela-oficial")
RES = os.path.join(OFICIAL, "usr/share/minitela/resources")
ACF_DIR = os.path.join(RES, "ACF")
PROJETO = os.path.join(ACF_DIR, "file.zip")
IDE = os.path.join(OFICIAL, "IDE_utils")
WORK = os.path.join(OFICIAL, "trabalho")
WINEPREFIX = os.path.join(OFICIAL, "wine")
SIZE = 240
# As três imagens da tela "Personalizar imagens" dentro do projeto (iguais às do minitela-r15)
SLOTS = {1: "1i1h1e37393671471.gif", 2: "1h1k1e37393671464.gif", 3: "1h1m1e37393671466.gif"}
PADRAO = {i: os.path.join(RES, "gifs_imagens", f"img{i}.jpg") for i in SLOTS}

_spec = importlib.util.spec_from_file_location("mc", os.path.join(HERE, "vendor", "minitela_ctl.py"))
mc = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(mc)


def die(msg):
    sys.exit(f"erro: {msg}")


def need_oficial():
    if not os.path.isfile(PROJETO):
        die(f"arquivos do pacote oficial não encontrados em {OFICIAL} (ver README.md, seção Imagens)")


# --------------------------------------------------------------------- temas

def themes():
    out = {0: os.path.join(ACF_DIR, "Texture.acf")}
    for n in range(1, 22):
        p = os.path.join(ACF_DIR, f"Texture{n}.acf")
        if os.path.isfile(p):
            out[n] = p
    return out


def cmd_temas(_):
    need_oficial()
    for n, p in themes().items():
        nome = "padrão de fábrica" if n == 0 else f"tema {n}"
        previa = os.path.join(RES, "gifs_imagens", f"{n}.gif")
        print(f"{n:>2}  {nome:<18} {os.path.getsize(p) // 1024:>5} KiB   prévia: {previa}")


# ----------------------------------------------------------------- compilar

def wine_env():
    env = dict(os.environ, WINEPREFIX=WINEPREFIX, WINEDEBUG="-all", WINEDLLOVERRIDES="mscoree,mshtml=")
    env.pop("WINEARCH", None)
    return env


def ensure_wine():
    if not shutil.which("wine"):
        die("o Wine não está instalado: sudo pacman -S wine")
    if not os.path.isdir(os.path.join(WINEPREFIX, "drive_c")):
        print(f"criando o ambiente do Wine em {WINEPREFIX} (só na primeira vez, pode levar 1 min)…")
        env = wine_env()
        env["WINEARCH"] = "win64"
        subprocess.run(["wineboot", "-u"], env=env, capture_output=True, timeout=600)


def to_gif(src, dst):
    """Qualquer imagem → GIF 240x240 de 1 quadro (corte central, cores exatas)."""
    vf = (f"scale={SIZE}:{SIZE}:force_original_aspect_ratio=increase,crop={SIZE}:{SIZE},"
          "split[a][b];[a]palettegen=max_colors=256[p];[b][p]paletteuse=dither=none")
    r = subprocess.run(["ffmpeg", "-y", "-hide_banner", "-loglevel", "error", "-i", src,
                        "-vf", vf, "-frames:v", "1", dst], capture_output=True)
    if r.returncode or not os.path.getsize(dst):
        die("o ffmpeg falhou com " + src + ":\n" + r.stderr.decode(errors="replace")[:800])
    return dst


def cmd_compilar(args):
    need_oficial()
    if not 1 <= len(args.imagens) <= 3:
        die("passe de 1 a 3 imagens")
    if not os.path.isfile(os.path.join(IDE, "Gen", "AHMISimGenDemo_og.exe")):
        die(f"compilador não encontrado em {IDE}/Gen (ver README.md)")
    ensure_wine()
    build = os.path.join(WORK, "build")
    os.makedirs(build, exist_ok=True)

    gifs = {}
    for i in SLOTS:
        src = args.imagens[i - 1] if i <= len(args.imagens) else PADRAO[i]
        if not os.path.isfile(src):
            die(f"imagem não encontrada: {src}")
        gifs[i] = to_gif(src, os.path.join(build, f"slot{i}.gif"))
        print(f"imagem {i}: {os.path.basename(src)}" + ("" if i <= len(args.imagens) else "  (de fábrica)"))

    # Cópia do projeto com as imagens trocadas
    proj = os.path.join(build, "file.zip")
    inv = {v: k for k, v in SLOTS.items()}
    with zipfile.ZipFile(PROJETO) as zin, zipfile.ZipFile(proj, "w", zipfile.ZIP_DEFLATED) as zout:
        for it in zin.infolist():
            data = open(gifs[inv[it.filename]], "rb").read() if it.filename in inv else zin.read(it.filename)
            zout.writestr(it.filename, data)

    acf_out = os.path.join(IDE, "ACF")
    os.makedirs(acf_out, exist_ok=True)
    for f in os.listdir(acf_out):
        if f.endswith(".acf"):
            os.unlink(os.path.join(acf_out, f))
    print("compilando (compilador da fabricante, via Wine)…")
    cmd = ["wine", os.path.join(IDE, "Gen", "AHMISimGenDemo_og.exe"), "-f", proj,
           "-m", "2", "-c", "0", "-e", "0", "-d", "0" if args.sem_dither else "1", "-o", acf_out]
    r = subprocess.run(cmd, cwd=os.path.join(IDE, "Gen"), input=b"13", env=wine_env(),
                       capture_output=True, timeout=600)
    saida = (r.stdout + r.stderr).decode(errors="replace")
    gerado = os.path.join(acf_out, "Texture.acf")
    if not os.path.isfile(gerado):
        print(saida[-1500:])
        die("o compilador não gerou o Texture.acf")
    dst = os.path.join(WORK, time.strftime("minitela-%Y%m%d-%H%M%S.acf"))
    shutil.copy2(gerado, dst)
    print(f"\npronto: {dst} ({os.path.getsize(dst) // 1024} KiB)")
    print(f"para gravar: python3 {os.path.abspath(__file__)} gravar '{dst}'")


# -------------------------------------------------------------------- gravar

def gravar(path, yes=False):
    if not os.path.isfile(path) or not path.endswith(".acf"):
        die(f"arquivo .acf não encontrado: {path}")
    data = open(path, "rb").read()
    if len(data) > mc.MAX_FILE_BYTES:
        die(f"arquivo grande demais para a tela ({len(data)} bytes)")
    print(f"arquivo : {path} ({len(data) // 1024} KiB)")
    print("destino : região de texturas da minitela (0x08100000) — nada mais é tocado")
    print("se a tela congelar depois: desligue o notebook por completo, ligue e rode 'imagens.py fabrica'")
    if not yes and input("gravar na minitela? [s/N] ").strip().lower() not in ("s", "sim"):
        sys.exit("cancelado")

    service = subprocess.run(["systemctl", "--user", "is-active", "--quiet", "minitela"]).returncode == 0
    if service:
        print("parando o serviço da minitela durante a gravação…")
        subprocess.run(["systemctl", "--user", "stop", "minitela"], check=False)
        time.sleep(1)
    port = os.path.realpath("/dev/minitela") if os.path.exists("/dev/minitela") else mc.find_port()
    if not port:
        die("minitela não encontrada (/dev/minitela)")
    mt = mc.Minitela(port)
    t0, last = time.monotonic(), [-1]

    def prog(pct):
        if pct != last[0]:
            last[0] = pct
            print(f"\r[{'#' * (pct // 4)}{'.' * (25 - pct // 4)}] {pct:3d}%  {time.monotonic() - t0:5.1f}s",
                  end="", flush=True)

    try:
        res = mt.upload(data, "texture", progress=prog)
        print(f"\n{'já estava gravado' if res == 'ja-gravado' else 'gravado'} em {time.monotonic() - t0:.1f}s")
    finally:
        mt.close()
        if service:
            time.sleep(4)               # a tela reinicia (e pode trocar de ttyACM) depois de gravar
            print("religando o serviço da minitela…")
            subprocess.run(["systemctl", "--user", "start", "minitela"], check=False)


def cmd_gravar(args):
    gravar(os.path.abspath(args.arquivo), args.yes)


def cmd_tema(args):
    need_oficial()
    t = themes()
    if args.n not in t:
        die(f"tema inválido: {args.n} (veja: imagens.py temas)")
    gravar(t[args.n], args.yes)


def cmd_fabrica(args):
    need_oficial()
    gravar(themes()[0], args.yes)


def main():
    ap = argparse.ArgumentParser(description="Imagens e temas da minitela (grava a flash da tela)")
    sub = ap.add_subparsers(dest="cmd", required=True)
    sub.add_parser("temas").set_defaults(fn=cmd_temas)
    t = sub.add_parser("tema")
    t.add_argument("n", type=int)
    t.add_argument("-y", "--yes", action="store_true")
    t.set_defaults(fn=cmd_tema)
    f = sub.add_parser("fabrica")
    f.add_argument("-y", "--yes", action="store_true")
    f.set_defaults(fn=cmd_fabrica)
    c = sub.add_parser("compilar")
    c.add_argument("imagens", nargs="+")
    c.add_argument("--sem-dither", action="store_true", help="cores chapadas (sem pontilhado)")
    c.set_defaults(fn=cmd_compilar)
    g = sub.add_parser("gravar")
    g.add_argument("arquivo")
    g.add_argument("-y", "--yes", action="store_true")
    g.set_defaults(fn=cmd_gravar)
    args = ap.parse_args()
    args.fn(args)


if __name__ == "__main__":
    main()
