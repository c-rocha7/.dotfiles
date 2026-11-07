pragma Singleton

// Clima: cidade pelo IP (ipwho.is; reserva: ipapi.co) e previsão pela Open-Meteo (grátis, sem cadastro).
// Uma consulta que falha não apaga a última resposta boa (fica salva e é reaproveitada).
// Atualiza ao iniciar e a cada 30 min (a cidade, a cada 3 h). Usado no painel do calendário.
// As respostas ficam em $XDG_RUNTIME_DIR/clima-{local,previsao}.json: o serviço da minitela lê
// de lá para preencher a página de clima dela (sem fazer outra consulta).

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string city: ""
    property real lat: NaN
    property real lon: NaN
    property bool ready: false
    property real temp: 0
    property int code: -1
    property bool isDay: true
    property var days: []        // [{ date: Date, max, min, code }] hoje, amanhã, depois
    property date updatedAt
    readonly property string runtime: Quickshell.env("XDG_RUNTIME_DIR")

    // Código WMO → [descrição, ícone de dia, ícone de noite] (Nerd Font, família weather)
    function info(c) {
        if (c === 0) return ["Céu limpo", "\u{e30d}", "\u{e32b}"];
        if (c === 1 || c === 2) return ["Parcialmente nublado", "\u{e302}", "\u{e37e}"];
        if (c === 3) return ["Nublado", "\u{e312}", "\u{e312}"];
        if (c === 45 || c === 48) return ["Neblina", "\u{e313}", "\u{e313}"];
        if (c >= 51 && c <= 57) return ["Garoa", "\u{e319}", "\u{e319}"];
        if ((c >= 61 && c <= 67) || (c >= 80 && c <= 82)) return ["Chuva", "\u{e318}", "\u{e318}"];
        if ((c >= 71 && c <= 77) || c === 85 || c === 86) return ["Neve", "\u{e31a}", "\u{e31a}"];
        if (c >= 95) return ["Tempestade", "\u{e31d}", "\u{e31d}"];
        return ["—", "\u{e374}", "\u{e374}"];
    }
    function description(c) { return info(c)[0]; }
    function icon(c, day) { return info(c)[day === false ? 2 : 1]; }

    function refresh() {
        if (isNaN(lat) || locationAge.elapsed > 3)
            locate.running = true;
        else
            forecast.running = true;
    }

    // Idade da localização, em "rodadas" de 1 h
    QtObject {
        id: locationAge
        property int elapsed: 0
    }

    Process {
        id: locate
        // Salva só se veio uma resposta com coordenadas; senão devolve a última boa.
        command: ["bash", "-c", `f="${root.runtime}/clima-local.json"
            for url in https://ipwho.is/ https://ipapi.co/json/; do
                if curl -fsS --max-time 10 "$url" -o "$f.tmp" && grep -q '"latitude"' "$f.tmp"; then mv "$f.tmp" "$f"; break; fi
            done
            rm -f "$f.tmp"; cat "$f" 2>/dev/null`]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const j = JSON.parse(text);
                    if (j.latitude === undefined) throw "sem coordenadas";
                    root.city = j.city ?? "";
                    root.lat = j.latitude;
                    root.lon = j.longitude;
                    locationAge.elapsed = 0;
                    forecast.running = true;
                } catch (e) {
                    console.warn("clima: não achei a localização:", e);
                }
            }
        }
    }

    Process {
        id: forecast
        command: ["bash", "-c", `curl -fsS --max-time 10 "https://api.open-meteo.com/v1/forecast?latitude=${root.lat}&longitude=${root.lon}&current=temperature_2m,weather_code,is_day&daily=weather_code,temperature_2m_max,temperature_2m_min&timezone=auto&forecast_days=3" -o "${root.runtime}/clima-previsao.json.tmp" && mv "${root.runtime}/clima-previsao.json.tmp" "${root.runtime}/clima-previsao.json"; cat "${root.runtime}/clima-previsao.json" 2>/dev/null`]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const j = JSON.parse(text);
                    root.temp = j.current.temperature_2m;
                    root.code = j.current.weather_code;
                    root.isDay = j.current.is_day === 1;
                    root.days = j.daily.time.map((t, i) => ({
                        date: new Date(t + "T12:00:00"),
                        max: j.daily.temperature_2m_max[i],
                        min: j.daily.temperature_2m_min[i],
                        code: j.daily.weather_code[i]
                    }));
                    root.updatedAt = new Date();
                    root.ready = true;
                } catch (e) {
                    console.warn("clima: previsão inválida:", e);
                }
            }
        }
    }

    Timer {
        running: true
        triggeredOnStart: true
        interval: 30 * 60 * 1000
        repeat: true
        onTriggered: root.refresh()
    }
    Timer {
        running: true
        interval: 60 * 60 * 1000
        repeat: true
        onTriggered: locationAge.elapsed++
    }
}
