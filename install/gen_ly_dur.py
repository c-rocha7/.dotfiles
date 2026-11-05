#!/usr/bin/env python3
"""Gera o desenho "noite Catppuccin" (montanhas + estrelas) para o ly e para o Limine.

Saídas:
  system/etc/ly/catppuccin.dur              ly (durdraw v7, 16 cores, estrelas piscando) → install/ly.sh
  system/boot/limine-tema/wallpaper.png     Limine, a mesma cena em 1920x1080      → install/limine-tema.sh
  system/boot/limine-tema/terminus-8x16b.f16  fonte Terminus negrito (IBM437) para o Limine

As cores são ÍNDICES da paleta do console (16 cores), que o startup.sh / kmscon trocam pela
Catppuccin Mocha; por isso aparecem exatas. Rodar de novo depois de mudar algo aqui:
    python3 ~/.dotfiles/install/gen_ly_dur.py   (e rode de novo ly.sh e limine-tema.sh)
"""

import gzip
import json
import math
import random
from pathlib import Path

WIDTH, HEIGHT = 256, 72   # maior que a tela: o ly corta o que sobra (alinhado na base, centralizado)
FRAMES = 4                # estrelas piscando
FRAMERATE = 1.5
SEED = 7                  # mesmo desenho a cada geração

# Índice da paleta do console → valor de cor do durdraw (inverso da tabela do ly, DurFile.zig:
# durcolor_table_to_color16). O fundo usa "valor + 1" na tabela, então fundo 0 = paleta 0 (base).
PALETTE_TO_DUR = {0: 0, 1: 5, 2: 3, 3: 7, 4: 2, 5: 6, 6: 4, 7: 8,
                  8: 9, 9: 13, 10: 11, 11: 15, 12: 10, 13: 14, 14: 12, 15: 16}
BASE, YELLOW, BLUE, MAUVE, SUBTEXT, SURFACE2, PINK, TEXT = 0, 3, 4, 5, 7, 8, 13, 15

rng = random.Random(SEED)


def ridge(base_height, amplitude, waves, phase):
    """Altura (em linhas, a partir da base) de uma cordilheira em cada coluna."""
    heights = []
    for x in range(WIDTH):
        t = x / WIDTH * 2 * math.pi
        h = base_height
        for i, (freq, weight) in enumerate(waves):
            h += amplitude * weight * math.sin(freq * t + phase + i * 1.7)
        h += rng.uniform(-0.6, 0.6)  # bordas menos "perfeitas"
        heights.append(max(1, round(h)))
    return heights


# Camadas de trás para a frente: (alturas, caractere, cor)
LAYERS = [
    (ridge(9, 3.0, [(3, 1.0), (7, 0.5), (13, 0.25)], 0.3), "░", MAUVE),
    (ridge(7, 2.5, [(4, 1.0), (9, 0.5), (17, 0.25)], 2.1), "▒", BLUE),
    (ridge(3, 1.5, [(5, 1.0), (11, 0.5), (23, 0.3)], 4.4), "█", SURFACE2),
]

# Estrelas só no céu (acima da montanha mais alta daquela coluna).
sky_top = [HEIGHT - max(layer[0][x] for layer in LAYERS) - 1 for x in range(WIDTH)]
stars = []
for x in range(WIDTH):
    for y in range(sky_top[x] - 1):
        if rng.random() < 0.012:
            color = rng.choice([TEXT, TEXT, TEXT, YELLOW, PINK, SUBTEXT])
            stars.append((x, y, color, rng.randrange(FRAMES)))

# Fases do brilho: cada estrela começa numa fase diferente.
TWINKLE = ["·", "+", "*", "+"]


def grid(n):
    """Caracteres e cores (índices da paleta) da cena no frame n."""
    chars = [[" "] * WIDTH for _ in range(HEIGHT)]
    colors = [[(TEXT, BASE)] * WIDTH for _ in range(HEIGHT)]
    for x, y, color, phase in stars:
        chars[y][x] = TWINKLE[(n + phase) % FRAMES]
        colors[y][x] = (color, BASE)
    for heights, char, color in LAYERS:
        for x, h in enumerate(heights):
            for y in range(HEIGHT - h, HEIGHT):
                chars[y][x] = char
                colors[y][x] = (color, BASE)
    return chars, colors


def frame(n):
    chars, colors = grid(n)
    contents = ["".join(row) for row in chars]
    # colorMap do durdraw: [x][y] = [frente, fundo]
    color_map = [[[PALETTE_TO_DUR[colors[y][x][0]], PALETTE_TO_DUR[colors[y][x][1]]]
                  for y in range(HEIGHT)] for x in range(WIDTH)]
    return {"frameNumber": n + 1, "delay": 0, "contents": contents, "colorMap": color_map}


movie = {"DurMovie": {
    "formatVersion": 7, "colorFormat": "16", "preferredFont": "fixed", "encoding": "utf-8",
    "name": "Noite Catppuccin", "artist": "dotfiles vision-r15m", "framerate": FRAMERATE,
    "sizeX": WIDTH, "sizeY": HEIGHT, "columns": WIDTH, "lines": HEIGHT, "extra": None,
    "frames": [frame(n) for n in range(FRAMES)],
}}

# Toda linha precisa ter exatamente WIDTH caracteres (o ly não confere e trava se faltar).
for f in movie["DurMovie"]["frames"]:
    assert all(len(line) == WIDTH for line in f["contents"]) and len(f["contents"]) == HEIGHT

out = Path(__file__).resolve().parent.parent / "system/etc/ly/catppuccin.dur"
out.write_bytes(gzip.compress(json.dumps(movie, ensure_ascii=False).encode("utf-8"), 9))
print(f"{out} ({out.stat().st_size // 1024} KiB, {WIDTH}x{HEIGHT}, {FRAMES} frames, {len(stars)} estrelas)")


# ---------------------------------------------------------------------------
# Limine (install/limine-tema.sh): a mesma cena como wallpaper 1920x1080 e a fonte Terminus.
# ---------------------------------------------------------------------------
from PIL import Image  # noqa: E402

# Paleta Catppuccin Mocha (mesmos índices do console)
RGB = {0: (0x1E, 0x1E, 0x2E), 3: (0xF9, 0xE2, 0xAF), 4: (0x89, 0xB4, 0xFA), 5: (0xCB, 0xA6, 0xF7),
       7: (0xBA, 0xC2, 0xDE), 8: (0x58, 0x5B, 0x70), 13: (0xF5, 0xC2, 0xE7), 15: (0xCD, 0xD6, 0xF4)}
CELL_W, CELL_H = 10, 20                    # célula de terminal (FiraCode 16 px) → 192x54 células
SCREEN_W, SCREEN_H = 1920, 1080
COLS, ROWS = SCREEN_W // CELL_W, SCREEN_H // CELL_H
SHADE = {"░": 4, "▒": 2, "█": 1}           # densidade do padrão de pixels (1 em cada N)


def render_cell(px, x0, y0, char, rgb):
    if char in SHADE:
        n = SHADE[char]
        for dy in range(CELL_H):
            for dx in range(CELL_W):
                # ░ = 1/4 dos pixels, ▒ = metade (xadrez), █ = cheio
                if n == 1 or (n == 2 and (dx + dy) % 2 == 0) or (n == 4 and dx % 2 == 0 and dy % 2 == 0):
                    px[x0 + dx, y0 + dy] = rgb
        return
    cx, cy = x0 + CELL_W // 2, y0 + CELL_H // 2
    dots = {"·": [(0, 0), (1, 0), (0, 1), (1, 1)],
            "+": [(0, 0), (1, 0), (-1, 0), (2, 0), (0, 1), (0, -1), (0, 2), (1, 1)],
            "*": [(0, 0), (1, 0), (-1, 0), (2, 0), (0, 1), (0, -1), (0, 2), (1, 1),
                  (-1, -1), (2, -1), (-1, 2), (2, 2)]}.get(char, [])
    for dx, dy in dots:
        px[cx + dx, cy + dy] = rgb


chars, colors = grid(0)
img = Image.new("RGB", (SCREEN_W, SCREEN_H), RGB[BASE])
px = img.load()
x_off, y_off = (WIDTH - COLS) // 2, HEIGHT - ROWS   # mesmo recorte do ly: centro, alinhado na base
for row in range(ROWS):
    for col in range(COLS):
        ch = chars[y_off + row][x_off + col]
        if ch != " ":
            render_cell(px, col * CELL_W, row * CELL_H, ch, RGB[colors[y_off + row][x_off + col][0]])
limine_dir = Path(__file__).resolve().parent.parent / "system/boot/limine-tema"
limine_dir.mkdir(parents=True, exist_ok=True)
wallpaper = limine_dir / "wallpaper.png"
img.save(wallpaper, optimize=True)
print(f"{wallpaper} ({wallpaper.stat().st_size // 1024} KiB)")

# Fonte: Terminus negrito 8x16 em IBM437 (ter-i16b, PSF1) → bitmap cru de 256 glifos que o Limine lê.
psf = gzip.decompress(Path("/usr/share/kbd/consolefonts/ter-i16b.psf.gz").read_bytes())
assert psf[:2] == b"\x36\x04" and psf[3] == 16, "ter-i16b não é PSF1 8x16"
font = limine_dir / "terminus-8x16b.f16"
font.write_bytes(psf[4:4 + 256 * 16])
print(f"{font} ({font.stat().st_size} bytes)")
