#!/usr/bin/env python3
# Gera quickshell/data/emojis.json a partir do emoji-test.txt (Unicode) e das
# anotações em português do CLDR (só é preciso rodar para atualizar a lista).
#
#   mkdir -p /tmp/emoji && cd /tmp/emoji
#   curl -fsSLO https://unicode.org/Public/emoji/latest/emoji-test.txt
#   curl -fsSL -o annotations-pt.json \
#     https://raw.githubusercontent.com/unicode-org/cldr-json/main/cldr-json/cldr-annotations-full/annotations/pt/annotations.json
#   python3 -I ~/.dotfiles/install/gen_emojis.py /tmp/emoji ~/.dotfiles/quickshell/data/emojis.json
import json
import re
import sys

src, out = sys.argv[1], sys.argv[2]

pt = json.load(open(f"{src}/annotations-pt.json", encoding="utf-8"))
pt = pt["annotations"]["annotations"]

SKIN = re.compile("[\U0001F3FB-\U0001F3FF]")  # tons de pele: ficam de fora
line_re = re.compile(r"^[0-9A-F ]+;\s*fully-qualified\s*#\s*(\S+)\s+E[\d.]+\s+(.+)$")

emojis, group = [], ""
for line in open(f"{src}/emoji-test.txt", encoding="utf-8"):
    if line.startswith("# group:"):
        group = line.split(":", 1)[1].strip()
        continue
    if group == "Component":
        continue
    m = line_re.match(line.strip())
    if not m:
        continue
    char, en_name = m.group(1), m.group(2)
    if SKIN.search(char):
        continue
    key = char.replace("️", "")
    info = pt.get(char) or pt.get(key) or {}
    name = (info.get("tts") or [en_name])[0]
    keywords = " ".join(info.get("default", []))
    emojis.append({"e": char, "n": name, "k": f"{keywords} {en_name}".strip()})

json.dump(emojis, open(out, "w", encoding="utf-8"), ensure_ascii=False, separators=(",", ":"))
print(len(emojis), "emojis")
