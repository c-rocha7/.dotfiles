#!/usr/bin/env python3
"""Agenda (Google Calendar pelos links iCal) para o Quickshell e a minitela.

Lê ~/.config/agenda/ical-url (fora do git: quem tem o link vê a agenda), um link por linha,
com nome opcional antes de "=":
    Pessoal = https://calendar.google.com/calendar/ical/.../basic.ics
    Trabalho = https://...
    Feriados = https://...        (o endereço público serve para agendas públicas)
Linhas vazias ou começando com # são ignoradas. Baixa cada .ics (guarda uma cópia em
~/.cache/agenda/ para quando estiver sem internet) e imprime uma linha JSON com os eventos do mês atual (desde o dia 1) até ~3 meses à frente, já com as repetições (RRULE) calculadas e o nome da agenda de cada um. Também salva
o resultado em $XDG_RUNTIME_DIR/agenda.json (a minitela lê de lá).

Só biblioteca padrão. Repetições suportadas: DAILY, WEEKLY (BYDAY), MONTHLY (BYMONTHDAY ou
BYDAY tipo 2TU / -1FR), YEARLY, com INTERVAL, COUNT, UNTIL, EXDATE e exceções (RECURRENCE-ID).
"""

import datetime as dt
import hashlib
import json
import os
import sys
import urllib.request
from zoneinfo import ZoneInfo

HOME = os.path.expanduser("~")
URL_FILE = os.path.join(HOME, ".config/agenda/ical-url")
CACHE_DIR = os.path.join(HOME, ".cache/agenda")
OUT = os.path.join(os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}"), "agenda.json")
LOCAL = dt.datetime.now().astimezone().tzinfo
DAYS_BEFORE = 7     # antes do dia 1 do mês atual (o calendário mostra o fim do mês anterior)
DAYS_AHEAD = 100   # a partir de hoje (dá para avançar uns 3 meses no calendário)
WEEKDAYS = ["MO", "TU", "WE", "TH", "FR", "SA", "SU"]


def emit(obj):
    text = json.dumps(obj, ensure_ascii=False)
    try:
        with open(OUT + ".tmp", "w") as f:
            f.write(text)
        os.replace(OUT + ".tmp", OUT)
    except OSError:
        pass
    print(text)
    sys.exit(0)


def read_sources():
    """[(nome, url)] do arquivo de links."""
    try:
        lines = open(URL_FILE).read().splitlines()
    except OSError:
        emit({"ok": False, "erro": "sem link (salve o endereço iCal em ~/.config/agenda/ical-url)"})
    out = []
    for line in lines:
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        name, sep, url = line.partition("=") if "=" in line.split("://")[0] else ("", "", line)
        name, url = (name.strip(), url.strip()) if sep else (f"Agenda {len(out) + 1}", line)
        if url.startswith(("http://", "https://", "file://", "webcal://")):
            url = url.replace("webcal://", "https://", 1)
            same = [i for i, (_, u) in enumerate(out) if u == url]
            if same:                                # link repetido: só troca "Agenda N" pelo nome dado
                if sep and out[same[0]][0].startswith("Agenda "):
                    out[same[0]] = (name, url)
                continue
            out.append((name, url))
    if not out:
        emit({"ok": False, "erro": "nenhum link válido em ~/.config/agenda/ical-url"})
    return out


def download(url):
    """Baixa um .ics; se falhar, usa a cópia do cache. Devolve (texto ou None, veio_do_cache)."""
    cache = os.path.join(CACHE_DIR, hashlib.sha1(url.encode()).hexdigest()[:16] + ".ics")
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "agenda-quickshell"})
        with urllib.request.urlopen(req, timeout=20) as r:
            text = r.read().decode("utf-8", "replace")
        if "BEGIN:VCALENDAR" not in text:
            raise ValueError("resposta não é uma agenda")
        os.makedirs(CACHE_DIR, exist_ok=True)
        with open(cache + ".tmp", "w") as f:
            f.write(text)
        os.replace(cache + ".tmp", cache)
        os.chmod(cache, 0o600)
        return text, False
    except Exception:
        try:
            return open(cache).read(), True
        except OSError:
            return None, False


def unfold(text):
    lines = []
    for raw in text.replace("\r\n", "\n").split("\n"):
        if raw[:1] in (" ", "\t") and lines:
            lines[-1] += raw[1:]
        else:
            lines.append(raw)
    return lines


def unescape(v):
    return v.replace("\\n", " ").replace("\\N", " ").replace("\\,", ",").replace("\\;", ";").replace("\\\\", "\\")


def parse_prop(line):
    """'DTSTART;TZID=X:2026...' → ('DTSTART', {'TZID': 'X'}, '2026...')"""
    head, _, value = line.partition(":")
    parts = head.split(";")
    params = {}
    for p in parts[1:]:
        k, _, v = p.partition("=")
        params[k.upper()] = v.strip('"')
    return parts[0].upper(), params, value


def parse_time(value, params):
    """Devolve (datetime local ou date, dia_inteiro)."""
    value = value.strip()
    if params.get("VALUE") == "DATE" or (len(value) == 8 and value.isdigit()):
        return dt.date(int(value[:4]), int(value[4:6]), int(value[6:8])), True
    t = dt.datetime.strptime(value[:15], "%Y%m%dT%H%M%S")
    if value.endswith("Z"):
        t = t.replace(tzinfo=dt.timezone.utc)
    elif "TZID" in params:
        try:
            t = t.replace(tzinfo=ZoneInfo(params["TZID"]))
        except Exception:
            t = t.replace(tzinfo=LOCAL)
    else:
        t = t.replace(tzinfo=LOCAL)
    return t.astimezone(LOCAL), False


def key(t):
    """Chave para comparar ocorrências (EXDATE/RECURRENCE-ID)."""
    return t.isoformat() if isinstance(t, dt.datetime) else t.isoformat()


def nth_weekday(year, month, wd, n):
    """n-ésimo dia da semana wd (0=seg) do mês; n<0 conta do fim. None se não existir."""
    if n > 0:
        first = dt.date(year, month, 1)
        d = first + dt.timedelta(days=(wd - first.weekday()) % 7 + 7 * (n - 1))
        return d if d.month == month else None
    nxt = dt.date(year + (month == 12), month % 12 + 1, 1)
    last = nxt - dt.timedelta(days=1)
    d = last - dt.timedelta(days=(last.weekday() - wd) % 7 + 7 * (-n - 1))
    return d if d.month == month else None


def occurrences(start, rule, window_end):
    """Gera as datas/horas de início de um evento repetido (até window_end)."""
    r = dict(p.split("=", 1) for p in rule.split(";") if "=" in p)
    freq = r.get("FREQ", "")
    interval = int(r.get("INTERVAL", "1") or 1)
    count = int(r["COUNT"]) if "COUNT" in r else None
    until = None
    if "UNTIL" in r:
        until, _ = parse_time(r["UNTIL"], {})
    is_dt = isinstance(start, dt.datetime)
    sdate = start.date() if is_dt else start

    def at(d):  # mesma hora do início, no dia d
        return dt.datetime.combine(d, start.timetz()) if is_dt else d

    def over_until(t):
        if until is None:
            return False
        if isinstance(until, dt.datetime) and is_dt:
            return t > until
        u = until.date() if isinstance(until, dt.datetime) else until
        return (t.date() if is_dt else t) > u

    n = 0
    end_date = window_end.date()
    for period in range(5000):
        days = []
        if freq == "DAILY":
            days = [sdate + dt.timedelta(days=period * interval)]
        elif freq == "WEEKLY":
            week0 = sdate - dt.timedelta(days=sdate.weekday()) + dt.timedelta(weeks=period * interval)
            byday = [WEEKDAYS.index(x[-2:]) for x in r.get("BYDAY", "").split(",") if x[-2:] in WEEKDAYS]
            days = [week0 + dt.timedelta(days=w) for w in sorted(byday or [sdate.weekday()])]
        elif freq == "MONTHLY":
            m = sdate.month - 1 + period * interval
            y, mo = sdate.year + m // 12, m % 12 + 1
            if "BYDAY" in r:
                for x in r["BYDAY"].split(","):
                    num = x[:-2]
                    if x[-2:] in WEEKDAYS and num.lstrip("-+").isdigit():
                        d = nth_weekday(y, mo, WEEKDAYS.index(x[-2:]), int(num))
                        if d:
                            days.append(d)
            else:
                for md in (r.get("BYMONTHDAY") or str(sdate.day)).split(","):
                    try:
                        days.append(dt.date(y, mo, int(md)))
                    except ValueError:
                        pass                        # ex.: dia 31 em mês de 30
        elif freq == "YEARLY":
            try:
                days = [sdate.replace(year=sdate.year + period * interval)]
            except ValueError:
                days = []                           # 29/02
        else:
            yield start
            return
        for d in sorted(days):
            if d < sdate:
                continue
            t = at(d)
            if over_until(t) or (count is not None and n >= count) or d > end_date:
                return
            n += 1
            yield t


def main():
    now = dt.datetime.now(LOCAL)
    today = now.replace(hour=0, minute=0, second=0, microsecond=0)
    w_start = today.replace(day=1) - dt.timedelta(days=DAYS_BEFORE)
    w_end = today + dt.timedelta(days=DAYS_AHEAD)
    out, failed, cached = [], [], []
    for index, (name, url) in enumerate(read_sources()):
        text, from_cache = download(url)
        if text is None:
            failed.append(name)
            continue
        if from_cache:
            cached.append(name)
        for e in parse_events(text, w_start, w_end):
            e["agenda"], e["cor"] = name, index
            out.append(e)
    if failed and not out and not cached:
        emit({"ok": False, "erro": "não consegui baixar a agenda (sem internet?)"})

    out.sort(key=lambda x: (x["inicio"], not x["diaInteiro"]))
    emit({"ok": True, "atualizado": now.isoformat(timespec="minutes"), "falharam": failed,
          "cache": cached, "eventos": out[:1500]})


def parse_events(text, w_start, w_end):
    """Eventos de um .ics que caem na janela [w_start, w_end)."""

    events, overrides = [], {}
    cur = None
    for line in unfold(text):
        if line == "BEGIN:VEVENT":
            cur = {"exdates": set()}
        elif line == "END:VEVENT" and cur is not None:
            if cur.get("start") is not None and cur.get("status") != "CANCELLED":
                events.append(cur)
            elif cur.get("recid") and cur.get("status") == "CANCELLED":
                overrides.setdefault(cur.get("uid"), set()).add(cur["recid"])
            cur = None
        elif cur is not None and ":" in line:
            name, params, value = parse_prop(line)
            if name == "DTSTART":
                cur["start"], cur["allday"] = parse_time(value, params)
            elif name == "DTEND":
                cur["end"], _ = parse_time(value, params)
            elif name == "SUMMARY":
                cur["title"] = unescape(value)
            elif name == "LOCATION":
                cur["location"] = unescape(value)
            elif name == "RRULE":
                cur["rrule"] = value
            elif name == "UID":
                cur["uid"] = value
            elif name == "STATUS":
                cur["status"] = value.upper()
            elif name == "EXDATE":
                for v in value.split(","):
                    cur["exdates"].add(key(parse_time(v, params)[0]))
            elif name == "RECURRENCE-ID":
                cur["recid"] = key(parse_time(value, params)[0])

    # Exceções: uma ocorrência alterada (RECURRENCE-ID) substitui a original da série
    for e in events:
        if e.get("recid"):
            overrides.setdefault(e.get("uid"), set()).add(e["recid"])

    out = []
    for e in events:
        start, allday = e["start"], e["allday"]
        dur = (e["end"] - start) if e.get("end") is not None else (dt.timedelta(days=1) if allday else dt.timedelta(0))
        skip = e["exdates"] | (overrides.get(e.get("uid"), set()) if not e.get("recid") else set())
        starts = occurrences(start, e["rrule"], w_end) if e.get("rrule") and not e.get("recid") else [start]
        for s in starts:
            if key(s) in skip:
                continue
            f = s + dur
            if allday:
                s_cmp = dt.datetime.combine(s, dt.time(), LOCAL)
                f_cmp = dt.datetime.combine(f, dt.time(), LOCAL)
            else:
                s_cmp, f_cmp = s, f
            if f_cmp <= w_start and not (s_cmp >= w_start) or s_cmp >= w_end:
                continue
            out.append({
                "inicio": s_cmp.isoformat(), "fim": f_cmp.isoformat(), "diaInteiro": allday,
                "titulo": e.get("title") or "(sem título)", "local": e.get("location") or "",
            })

    return out


if __name__ == "__main__":
    main()
