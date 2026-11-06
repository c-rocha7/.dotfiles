#!/usr/bin/env python3
"""Apaga a minitela no boot, antes da tela de login (minitela-apagar.service, como root).

Só age se minitela/config.json tiver "inicio": "apagada" (o mesmo que o serviço do usuário usa
depois do login). Manda um único comando: brilho 0 (SET_REGISTER, registro 7) — o mesmo que o
app oficial manda ao suspender. Nunca grava nada na flash.
Instalado por install/minitela.sh em /usr/local/lib/minitela/ (cópia em ~/.dotfiles/system/usr/...).
"""
import json
import os
import select
import struct
import sys
import termios
import time

CONFIG = "/home/7aauac/.dotfiles/minitela/config.json"
PORT = "/dev/minitela"


def main():
    try:
        if json.load(open(CONFIG)).get("inicio") != "apagada":
            return 0
    except (OSError, ValueError):
        return 0
    for _ in range(20):                       # espera o USB da tela aparecer (até 10 s)
        if os.path.exists(PORT):
            break
        time.sleep(0.5)
    else:
        print("minitela não encontrada", file=sys.stderr)
        return 0
    fd = os.open(PORT, os.O_RDWR | os.O_NOCTTY | os.O_NONBLOCK)
    try:
        attrs = termios.tcgetattr(fd)
        attrs[0], attrs[1], attrs[3] = termios.IGNPAR, 0, 0
        attrs[2] = termios.CS8 | termios.CREAD | termios.CLOCAL      # sem HUPCL: fechar não reinicia a tela
        attrs[4] = attrs[5] = termios.B115200
        attrs[6][termios.VMIN] = attrs[6][termios.VTIME] = 0
        termios.tcsetattr(fd, termios.TCSANOW, attrs)
        time.sleep(1.5)                       # abrir a porta reinicia a tela; ela ignora comandos por ~1 s
        termios.tcflush(fd, termios.TCIOFLUSH)
        content = bytes([0x80]) + struct.pack(">HI", 7, 0)          # brilho = 0
        os.write(fd, b"AH" + struct.pack(">HH", len(content) + 2, 0x0090) + content + b"\x00\x00MI")
        select.select([fd], [], [], 0.5)      # dá tempo da confirmação chegar
        try:
            os.read(fd, 256)
        except OSError:
            pass
        print("minitela apagada")
    finally:
        os.close(fd)
    return 0


if __name__ == "__main__":
    sys.exit(main())
