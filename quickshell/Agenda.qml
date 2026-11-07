pragma Singleton

// Agenda (Google Calendar pelo link secreto iCal): scripts/agenda.py a cada 15 min.
// Eventos do mês atual até ~3 meses à frente; usada no painel do calendário (lista + pontinhos nos dias)
// e na minitela (lembrete do próximo evento, via $XDG_RUNTIME_DIR/agenda.json).

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var data: null
    readonly property bool ok: data?.ok === true
    readonly property var events: ok ? data.eventos.map(e => Object.assign({}, e, {
            start: new Date(e.inicio), end: new Date(e.fim)
        })) : []
    // Dias com evento (para o calendário)
    readonly property var days: {
        const m = {};
        for (const e of events) {
            const d = new Date(e.start);
            do {
                m[Qt.formatDate(d, "yyyy-MM-dd")] = true;
                d.setDate(d.getDate() + 1);
            } while (e.diaInteiro && d < e.end);
        }
        return m;
    }

    function upcoming(now, n) {
        return events.filter(e => e.end > now).slice(0, n);
    }
    // "Hoje 14:00", "Amanhã 09:30", "seg. 10/11 · dia inteiro"
    function when(e, now) {
        const day0 = new Date(now.getFullYear(), now.getMonth(), now.getDate());
        const d = Math.round((new Date(e.start.getFullYear(), e.start.getMonth(), e.start.getDate()) - day0) / 86400000);
        const dayText = d <= 0 ? "Hoje" : d === 1 ? "Amanhã" : Qt.locale().toString(e.start, "ddd dd/MM");
        if (e.diaInteiro)
            return `${dayText} · dia inteiro`;
        const live = e.start <= now && e.end > now;
        return `${dayText} ${Qt.formatTime(e.start, "HH:mm")}${live ? " · agora" : ""}`;
    }

    function refresh() { if (!proc.running) proc.running = true; }

    Process {
        id: proc
        command: ["python3", "-I", Quickshell.shellPath("scripts/agenda.py")]
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.data = JSON.parse(text); } catch (e) { console.warn("agenda.py:", e); }
            }
        }
    }
    Timer {
        running: true
        triggeredOnStart: true
        interval: 15 * 60 * 1000
        repeat: true
        onTriggered: root.refresh()
    }

    IpcHandler {
        target: "agenda"
        function atualizar(): void { root.refresh(); }
    }
}
