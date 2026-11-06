#!/usr/bin/env python3
"""minitela: controla a minitela (1,54", 240x240) do Positivo Vision R15M no Arch.

A tela é um controlador GC9002 ("AHMI") ligado por USB serial (CDC-ACM, CherryUSB
"sxw-admin CDC_DEMO", 0324:0324). O firmware já desenha as páginas (mensagens, lembrete,
sistema, clima, gifs); aqui só PREENCHEMOS valores (comando SET_REGISTER).

Segurança (achados dos projetos de engenharia reversa, ver README.md):
  - NUNCA enviamos HANDSHAKE (põe a tela em modo de gravação), SWITCH_STATE, REQUEST/
    DOWNLOAD_DATA (gravam a flash) nem REBOOT. Só SET_REGISTER.
  - Texto vazio corrompe a tabela de registros da tela: mandamos " " no lugar.
  - Repetir o mesmo valor sem parar também corrompe: só enviamos quando muda.
  - Só usamos registros que este firmware tem (CPU, GPU, música etc. não existem).

Uso:
  minitela.py daemon                       # serviço (systemd --user: minitela.service)
  minitela.py brilho 60                    # 0-100 (fala com o serviço)
  minitela.py pagina sistema               # mensagens | lembrete | sistema | clima | gif1-3
  minitela.py notificar "Fulano" "oi!"     # mostra na página de mensagens
  minitela.py lembrete "Reunião às 15h"     # lembrete "" volta ao automático (música / CPU)
  minitela.py estado
  minitela.py botao                        # botão: sistema → mensagens → lembrete → imagens 1-3 → apagada
"""

import argparse
import glob
import json
import os
import re
import select
import signal
import socket
import struct
import subprocess
import sys
import termios
import time

PORT_GLOBS = ["/dev/minitela", "/dev/serial/by-id/usb-CherryUSB_sxw-admin_CDC_DEMO_*-if00"]
RUNTIME = os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}")
SOCK_PATH = os.path.join(RUNTIME, "minitela.sock")

# ------------------------------------------------------------------ protocolo

CMD_SET_REGISTER = 0x0090
HDR_NUM, HDR_STR = 0x80, 0xD0

REG = {
    "pagina": 2, "data": 4, "hora": 5, "brilho": 7,
    "bateria": 1082, "wifi": 1083, "bluetooth": 1085, "lembrete": 1090,
    "notif_de": 1140, "notif_texto": 1141, "bateria_icone": 1150,
    "whatsapp_logo": 2005, "data_hora": 2006,
    "notif_gatilho1": 2025, "notif_gatilho2": 2026,
}
STR_CAP = {1140: 36, 1141: 96, 1090: 100}     # bytes UTF-8; os demais aceitam 32
PAGES = {"mensagens": 1, "lembrete": 2, "sistema": 3, "clima": 4, "gif1": 5, "gif2": 6, "gif3": 7}


def _frame(content: bytes) -> bytes:
    # 'AH' | tamanho(2) | comando(2) | conteúdo | crc 0000 (o app oficial também manda sem CRC) | 'MI'
    return b"AH" + struct.pack(">HH", len(content) + 2, CMD_SET_REGISTER) + content + b"\x00\x00MI"


def frame_nums(pairs):
    content = bytes([HDR_NUM | ((len(pairs) - 1) & 0x0F)])
    for reg, value in pairs:
        content += struct.pack(">HI", reg, int(value) & 0xFFFFFFFF)
    return _frame(content)


def clean_text(reg: int, text: str) -> bytes:
    """Uma linha só, cortada no limite do campo sem quebrar caractere; nunca vazia."""
    text = re.sub(r"\s+", " ", str(text)).strip()
    data = text.encode("utf-8")[: STR_CAP.get(reg, 32)].decode("utf-8", "ignore").encode("utf-8")
    return data or b" "


def frame_str(reg: int, text: str) -> bytes:
    data = clean_text(reg, text)
    return _frame(struct.pack(">BHH", HDR_STR, reg, len(data)) + data)


# ---------------------------------------------------------------------- porta

RESPONSE = 0x00D0                # resposta do SET_REGISTER (1º byte: 0 leitura num., 1 texto, 2 ack)
HDR_READ_NUM = 0xC0
HDR_READ_STR = 0xE0
GAP = 0.15                       # intervalo mínimo entre comandos: mais rápido que isso corrompe a tela


def parse_frames(buf: bytearray):
    """Tira de buf os quadros completos 'AH..MI' e devolve [(comando, conteúdo)]."""
    out = []
    while True:
        i = buf.find(b"AH")
        if i < 0:
            del buf[:]
            return out
        del buf[:i]
        if len(buf) < 8:
            return out
        size = struct.unpack(">H", buf[2:4])[0] & 0x7FFF
        total = size + 8
        if len(buf) < total:
            return out
        frame = bytes(buf[:total])
        if frame[-2:] != b"MI":
            del buf[:2]
            continue
        out.append((struct.unpack(">H", frame[4:6])[0], frame[6:6 + size - 2]))
        del buf[:total]


class Panel:
    """Porta serial em modo raw (só termios). Um comando por vez: escreve, espera a
    confirmação da tela e respeita o intervalo mínimo. Só manda o que mudou."""

    def __init__(self, on_unsolicited=None):
        self.fd = None
        self.cache = {}
        self.buf = bytearray()
        self.last_write = 0.0
        self.on_unsolicited = on_unsolicited or (lambda cmd, data: None)

    def find(self):
        for pattern in PORT_GLOBS:
            hits = sorted(glob.glob(pattern))
            if hits:
                return hits[0]
        return None

    def open(self):
        path = self.find()
        if not path:
            return False
        try:
            fd = os.open(path, os.O_RDWR | os.O_NOCTTY | os.O_NONBLOCK)
        except OSError as e:
            log(f"não abriu {path}: {e}")
            return False
        try:
            attrs = termios.tcgetattr(fd)
            attrs[0], attrs[1], attrs[3] = termios.IGNPAR, 0, 0
            attrs[2] = termios.CS8 | termios.CREAD | termios.CLOCAL
            attrs[4] = attrs[5] = termios.B115200
            attrs[6][termios.VMIN] = 0
            attrs[6][termios.VTIME] = 0
            termios.tcsetattr(fd, termios.TCSANOW, attrs)
            time.sleep(1.5)             # abrir a porta reinicia a tela; ela ignora comandos por ~1 s
            termios.tcflush(fd, termios.TCIOFLUSH)
        except (termios.error, OSError) as e:
            # ex.: o USB da tela ainda está reiniciando (volta da suspensão): tenta de novo depois
            log(f"minitela ainda não respondeu ({e}); tento de novo em 5 s")
            os.close(fd)
            return False
        self.fd, self.cache, self.buf = fd, {}, bytearray()
        log(f"minitela conectada em {os.path.realpath(path)}")
        return True

    def close(self):
        if self.fd is not None:
            try:
                os.close(self.fd)
            except OSError:
                pass
        self.fd, self.cache, self.buf = None, {}, bytearray()

    def poll(self, timeout=0.0):
        """Lê o que chegou. Respostas de leitura/ack são devolvidas; o resto vai para o log."""
        if self.fd is None:
            return []
        try:
            r, _, _ = select.select([self.fd], [], [], timeout)
            if r:
                chunk = os.read(self.fd, 4096)
                if chunk:
                    self.buf.extend(chunk)
        except (BlockingIOError, InterruptedError):
            pass
        except OSError as e:
            log(f"erro lendo da minitela ({e}); vou reconectar")
            self.close()
            return []
        frames = parse_frames(self.buf)
        replies = []
        for cmd, data in frames:
            if cmd == RESPONSE:
                replies.append(data)
            else:
                self.on_unsolicited(cmd, data)
        return replies

    def transact(self, frame: bytes, want=2, timeout=0.4):
        """Envia um quadro e espera a resposta da classe `want` (2 = ack de escrita, 0 = leitura)."""
        if self.fd is None:
            return None
        wait = GAP - (time.monotonic() - self.last_write)
        if wait > 0:
            time.sleep(wait)
        self.poll(0)                    # descarta respostas antigas antes de mandar
        view = memoryview(frame)
        try:
            while view:
                try:
                    view = view[os.write(self.fd, view):]
                except BlockingIOError:
                    select.select([], [self.fd], [], 1.0)
        except OSError as e:
            log(f"erro escrevendo na minitela ({e}); vou reconectar")
            self.close()
            return None
        self.last_write = time.monotonic()
        deadline = self.last_write + timeout
        while self.fd is not None and time.monotonic() < deadline:
            for data in self.poll(max(0.0, deadline - time.monotonic())):
                if data and (data[0] >> 4) == want:
                    return data
        return None

    def set(self, name, value, force=False):
        reg = REG[name]
        if not force and self.cache.get(reg) == value:
            return
        frame = frame_str(reg, value) if isinstance(value, str) else frame_nums([(reg, value)])
        if self.transact(frame) is not None:
            self.cache[reg] = value
        elif self.fd is not None:
            log(f"sem confirmação para {name}={value!r} (vou tentar de novo)")

    def set_many(self, pairs, force=False):
        """Vários números num quadro só (ex.: data + hora)."""
        todo = [(REG[n], v) for n, v in pairs if force or self.cache.get(REG[n]) != v]
        if todo and self.transact(frame_nums(todo)) is not None:
            for reg, v in todo:
                self.cache[reg] = v

    def read_str(self, name):
        reg = REG[name]
        cap = STR_CAP.get(reg, 32)
        data = self.transact(_frame(struct.pack(">BHH", HDR_READ_STR, reg, cap)), want=1)
        if data and len(data) >= 5 and struct.unpack(">H", data[1:3])[0] == reg:
            size = struct.unpack(">H", data[3:5])[0]
            return data[5:5 + size].split(b"\x00", 1)[0].decode("utf-8", "replace")
        return None

    def read_num(self, name):
        reg = REG[name]
        data = self.transact(_frame(bytes([HDR_READ_NUM]) + struct.pack(">H", reg)), want=0)
        if data and len(data) >= 7 and struct.unpack(">H", data[1:3])[0] == reg:
            return struct.unpack(">I", data[3:7])[0]
        return None


# ------------------------------------------------------------- informações

def log(msg):
    print(msg, flush=True)


def battery():
    for base in sorted(glob.glob("/sys/class/power_supply/BAT*")):
        try:
            return int(open(f"{base}/capacity").read().strip())
        except (OSError, ValueError):
            pass
    return None


def battery_icon(pct):
    # o widget só tem 4 imagens (0..3); acima disso o ícone some
    return 0 if pct < 25 else 1 if pct < 50 else 2 if pct < 75 else 3


def run(cmd, timeout=3):
    try:
        return subprocess.run(cmd, capture_output=True, text=True, timeout=timeout).stdout
    except (OSError, subprocess.SubprocessError):
        return ""


def wifi_name():
    for line in run(["nmcli", "-t", "-f", "NAME,TYPE", "connection", "show", "--active"]).splitlines():
        name, _, kind = line.rpartition(":")
        if kind == "802-11-wireless":
            return name.replace("\\:", ":")
    return "sem Wi-Fi"


def bluetooth_name():
    for line in run(["bluetoothctl", "devices", "Connected"]).splitlines():
        parts = line.split(" ", 2)
        if len(parts) == 3 and parts[0] == "Device":
            return parts[2]
    return "nenhum"


_cpu_prev = None


def cpu_percent():
    """Uso de CPU desde a leitura anterior (a primeira só estabelece a base)."""
    global _cpu_prev
    try:
        fields = [int(x) for x in open("/proc/stat").readline().split()[1:]]
    except (OSError, ValueError):
        return None
    idle, total = fields[3] + fields[4], sum(fields)
    prev, _cpu_prev = _cpu_prev, (idle, total)
    if not prev or total == prev[1]:
        return None
    return round(100 * (1 - (idle - prev[0]) / (total - prev[1])))


def ram_percent():
    info = {}
    try:
        for line in open("/proc/meminfo"):
            key, value = line.split(":", 1)
            info[key] = int(value.split()[0])
        return round(100 * (1 - info["MemAvailable"] / info["MemTotal"]))
    except (OSError, KeyError, ValueError):
        return None


def cpu_temp():
    for hw in glob.glob("/sys/class/hwmon/hwmon*"):
        try:
            if open(f"{hw}/name").read().strip() == "k10temp":
                return round(int(open(f"{hw}/temp1_input").read()) / 1000)
        except (OSError, ValueError):
            pass
    return None


def now_playing():
    """(título, artista) do player tocando agora (MPRIS via playerctl), ou None."""
    out = run(["playerctl", "metadata", "--format", "{{status}}\t{{title}}\t{{artist}}"], timeout=2)
    for line in out.splitlines():
        parts = line.split("\t")
        if len(parts) == 3 and parts[0] == "Playing" and parts[1].strip():
            return parts[1].strip(), parts[2].strip()
    return None


def system_line():
    cpu, ram, temp = cpu_percent(), ram_percent(), cpu_temp()
    items = []
    if cpu is not None:
        items.append(f"CPU {cpu}%")
    if ram is not None:
        items.append(f"RAM {ram}%")
    if temp is not None:
        items.append(f"{temp}°C")
    return "  ".join(items) or " "


# --------------------------------------------------------------------- daemon

class Daemon:
    def __init__(self, brightness):
        self.panel = Panel(on_unsolicited=self.unsolicited)
        self.brightness = brightness
        self.blanked = False            # tela bloqueada / suspensa
        self.user_off = False           # apagada pelo botão da minitela (vale até o próximo toque)
        self.page = PAGES["sistema"]
        self.back_to_system_at = None
        self.next_slow = 0              # wifi/bluetooth (a cada 30 s)
        self.slow = {"wifi": "sem Wi-Fi", "bluetooth": "nenhum"}
        self.reminder = None            # lembrete definido pelo usuário (None = automático)
        self.track = None               # música tocando (para mostrar quando muda)

    # --- conteúdo ---------------------------------------------------------

    def push_all(self, force=False):
        p = self.panel
        now = time.localtime()
        p.set("data_hora", time.strftime("%d/%m %H:%M", now), force)
        # data e hora "BCD": os dígitos decimais lidos como hexadecimal (como o app oficial)
        p.set_many([("data", int(time.strftime("%Y%m%d", now), 16)),
                    ("hora", int(time.strftime("%H%M", now) + "00", 16))], force)
        pct = battery()
        if pct is not None:
            p.set("bateria", f"{pct}%", force)
            p.set("bateria_icone", battery_icon(pct), force)
        if time.monotonic() >= self.next_slow or force:
            self.slow = {"wifi": wifi_name(), "bluetooth": bluetooth_name()}
            self.next_slow = time.monotonic() + 30
        p.set("wifi", self.slow["wifi"], force)
        p.set("bluetooth", self.slow["bluetooth"], force)
        p.set("whatsapp_logo", 0, force)
        p.set("lembrete", self.reminder_text(), force)
        p.set("pagina", self.page, force)
        p.set("brilho", self.effective_brightness(), force)

    def reminder_text(self):
        """Página de lembrete: seu lembrete > música tocando > CPU/RAM/temperatura."""
        if self.reminder:
            return self.reminder
        track = now_playing()
        if track != self.track:
            self.track = track
            # música nova: mostra por 6 s, só se a minitela estiver na página de sistema
            if track and self.page == PAGES["sistema"] and not (self.blanked or self.user_off):
                self.page = PAGES["lembrete"]
                self.back_to_system_at = time.monotonic() + 6
        if track:
            title, artist = track
            return f"Tocando: {title}" + (f" - {artist}" if artist else "")
        return system_line()

    def effective_brightness(self):
        return 0 if (self.blanked or self.user_off) else self.brightness

    # Botão da minitela (tecla XF86Launch7, atalho no hypr/hyprland.lua): cada toque avança.
    BUTTON_CYCLE = ["sistema", "mensagens", "lembrete", "gif1", "gif2", "gif3", "apagada"]

    def button(self):
        current = "apagada" if self.user_off else next(
            (n for n in self.BUTTON_CYCLE if PAGES.get(n) == self.page), "sistema")
        nxt = self.BUTTON_CYCLE[(self.BUTTON_CYCLE.index(current) + 1) % len(self.BUTTON_CYCLE)]
        if nxt == "apagada":
            self.user_off = True
        else:
            self.user_off = False
            self.show_page(PAGES[nxt])
        self.panel.set("brilho", self.effective_brightness())
        return nxt

    def unsolicited(self, cmd, data):
        # A tela mandou algo sem ser pedido (ex.: o botão da minitela?). Registra para estudar.
        log(f"mensagem espontânea da minitela: comando 0x{cmd:04X} dados {data.hex(' ')}")

    def show_page(self, page, hold=None):
        self.page = page
        self.back_to_system_at = time.monotonic() + hold if hold else None
        self.panel.set("pagina", page)

    def notify(self, sender, text):
        if self.blanked or self.user_off:
            return
        self.panel.set("notif_de", sender or " ")
        self.panel.set("notif_texto", text or " ")
        self.panel.set("notif_gatilho1", 1, force=True)
        self.panel.set("notif_gatilho2", 1, force=True)
        self.show_page(PAGES["mensagens"], hold=10)

    def set_blank(self, blank, why, reconnect=False):
        if blank != self.blanked:
            log(f"{'apagando' if blank else 'acendendo'} a minitela ({why})")
        self.blanked = blank
        if reconnect:
            # ao voltar da suspensão a tela pode ter sido reiniciada: reconecta e manda tudo
            self.panel.close()
        else:
            self.panel.set("brilho", self.effective_brightness())

    # --- comandos pelo socket ------------------------------------------------

    def command(self, msg):
        cmd = msg.get("cmd")
        if cmd == "brilho":
            self.brightness = max(0, min(100, int(msg["valor"])))
            self.user_off = False
            self.panel.set("brilho", self.effective_brightness())
        elif cmd == "pagina":
            value = msg["valor"]
            page = PAGES.get(value) if not str(value).isdigit() else int(value)
            if page not in PAGES.values():
                return {"erro": f"página inválida: {value} ({', '.join(PAGES)})"}
            self.show_page(page)
        elif cmd == "notificar":
            self.notify(msg.get("de", ""), msg.get("texto", ""))
        elif cmd == "botao":
            return {"ok": True, "agora": self.button()}
        elif cmd == "lembrete":
            self.reminder = (msg.get("texto") or "").strip() or None   # vazio = volta ao automático
            self.panel.set("lembrete", self.reminder_text())
        elif cmd != "estado":
            return {"erro": f"comando desconhecido: {cmd}"}
        lido = {}
        if cmd == "estado" and self.panel.fd is not None:
            lido = {"tela_pagina": self.panel.read_num("pagina"), "tela_brilho": self.panel.read_num("brilho"),
                    "tela_lembrete": self.panel.read_str("lembrete")}
        return {"ok": True, "conectada": self.panel.fd is not None, "brilho": self.brightness, **lido,
                "apagada": self.blanked, "desligada_no_botao": self.user_off, "pagina": self.page, **self.slow}

    # --- laço principal -------------------------------------------------------

    def run(self):
        try:
            os.unlink(SOCK_PATH)
        except FileNotFoundError:
            pass
        server = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        server.bind(SOCK_PATH)
        os.chmod(SOCK_PATH, 0o600)
        server.listen(4)

        # Notificações (sessão) e bloqueio/suspensão (sistema), lidos do D-Bus.
        notif = subprocess.Popen(
            ["dbus-monitor", "--session",
             "type='method_call',interface='org.freedesktop.Notifications',member='Notify'"],
            stdout=subprocess.PIPE, text=True, bufsize=1)
        system = subprocess.Popen(
            ["dbus-monitor", "--system",
             "type='signal',interface='org.freedesktop.login1.Manager',member='PrepareForSleep'",
             "type='signal',interface='org.freedesktop.login1.Session',member='Lock'",
             "type='signal',interface='org.freedesktop.login1.Session',member='Unlock'"],
            stdout=subprocess.PIPE, text=True, bufsize=1)
        notif_parser = NotifyParser()
        last_system = ""

        stop = []                       # "sinal" = parada pedida; "dbus" = monitor do D-Bus caiu
        signal.signal(signal.SIGTERM, lambda *_: stop.append("sinal"))
        signal.signal(signal.SIGINT, lambda *_: stop.append("sinal"))
        next_tick = 0
        log(f"minitela: serviço iniciado (socket {SOCK_PATH})")

        while not stop:
            if self.panel.fd is None and time.monotonic() >= next_tick:
                if self.panel.open():
                    self.push_all(force=True)
            if self.panel.fd is not None and time.monotonic() >= next_tick:
                if self.back_to_system_at and time.monotonic() >= self.back_to_system_at:
                    self.show_page(PAGES["sistema"])
                self.push_all()
            if time.monotonic() >= next_tick:
                next_tick = time.monotonic() + 5

            fds = [server, notif.stdout, system.stdout] + ([self.panel.fd] if self.panel.fd is not None else [])
            try:
                ready, _, _ = select.select(fds, [], [], 1.0)
            except InterruptedError:
                continue
            for r in ready:
                if r is server:
                    self._serve(server)
                elif r is notif.stdout:
                    line = notif.stdout.readline()
                    if not line:
                        stop.append("dbus")
                        break
                    done = notif_parser.feed(line)
                    if done:
                        app, summary, body = done
                        self.notify(summary or app, body or summary)
                elif r is system.stdout:
                    line = system.stdout.readline()
                    if not line:
                        stop.append("dbus")
                        break
                    if "member=PrepareForSleep" in line or "member=Lock" in line or "member=Unlock" in line:
                        last_system = line
                        if "member=Lock" in line:
                            self.set_blank(True, "tela bloqueada")
                        elif "member=Unlock" in line:
                            self.set_blank(False, "tela desbloqueada")
                            next_tick = 0
                    elif "PrepareForSleep" in last_system and line.strip().startswith("boolean"):
                        waking = line.strip().endswith("false")
                        self.set_blank(not waking, "suspensão", reconnect=waking)
                        if waking:
                            next_tick = time.monotonic() + 3   # dá tempo do USB da tela voltar
                        last_system = ""
                elif r == self.panel.fd:
                    self.panel.poll(0)

        for proc in (notif, system):
            proc.terminate()
        server.close()
        try:
            os.unlink(SOCK_PATH)
        except FileNotFoundError:
            pass
        self.panel.close()
        log(f"minitela: serviço encerrado ({stop[0]})")
        return 0 if stop[0] == "sinal" else 1     # 1 → o systemd reinicia

    def _serve(self, server):
        conn, _ = server.accept()
        with conn:
            conn.settimeout(2)
            try:
                data = conn.recv(8192)
                reply = self.command(json.loads(data.decode("utf-8")))
            except Exception as e:      # comando malformado não derruba o serviço
                reply = {"erro": str(e)}
            conn.sendall(json.dumps(reply, ensure_ascii=False).encode("utf-8"))


class NotifyParser:
    """Lê a saída do dbus-monitor e devolve (app, título, texto) de cada Notify.

    Os argumentos vêm como linhas '   string "..."' (o texto pode ter várias linhas):
    app_name, app_icon, summary, body são as 4 primeiras strings.
    """

    def __init__(self):
        self.strings = None
        self.partial = None

    def feed(self, line):
        if "member=Notify" in line:
            self.strings, self.partial = [], None
            return None
        if self.strings is None:
            return None
        if self.partial is not None:
            self.partial += "\n" + line.rstrip("\n")
        elif line.startswith('   string "'):
            self.partial = line.rstrip("\n")[len('   string "'):]
        else:
            return None
        if self.partial.endswith('"') and not self.partial.endswith('\\"'):
            self.strings.append(self.partial[:-1])
            self.partial = None
            if len(self.strings) == 4:
                app, _icon, summary, body = self.strings
                self.strings = None
                body = re.sub(r"<[^>]+>", "", body)   # tira marcação (<b>, <a ...>)
                return app, summary, body
        return None


# ------------------------------------------------------------------------ CLI

def send(msg):
    s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    try:
        s.connect(SOCK_PATH)
    except OSError:
        sys.exit("o serviço não está rodando (systemctl --user start minitela)")
    with s:
        s.sendall(json.dumps(msg).encode("utf-8"))
        s.shutdown(socket.SHUT_WR)
        reply = json.loads(s.recv(8192).decode("utf-8"))
    if "erro" in reply:
        sys.exit(reply["erro"])
    return reply


def main():
    ap = argparse.ArgumentParser(description="Minitela do Positivo Vision R15M")
    sub = ap.add_subparsers(dest="cmd", required=True)
    d = sub.add_parser("daemon", help="serviço que mantém a tela atualizada")
    d.add_argument("--brilho", type=int, default=60)
    sub.add_parser("brilho").add_argument("valor", type=int)
    sub.add_parser("pagina").add_argument("valor", help=" | ".join(PAGES))
    n = sub.add_parser("notificar")
    n.add_argument("de")
    n.add_argument("texto")
    sub.add_parser("lembrete").add_argument("texto")
    sub.add_parser("estado")
    sub.add_parser("botao", help="o mesmo que o botão da minitela (próxima página / apagar)")
    args = ap.parse_args()

    if args.cmd == "daemon":
        sys.exit(Daemon(max(0, min(100, args.brilho))).run())
    msg = {"cmd": args.cmd}
    if args.cmd in ("brilho", "pagina"):
        msg["valor"] = args.valor
    elif args.cmd == "notificar":
        msg.update(de=args.de, texto=args.texto)
    elif args.cmd == "lembrete":
        msg["texto"] = args.texto
    reply = send(msg)
    print(json.dumps(reply, ensure_ascii=False, indent=2) if args.cmd == "estado"
          else reply.get("agora", "ok"))


if __name__ == "__main__":
    main()
