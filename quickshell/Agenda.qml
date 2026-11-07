pragma Singleton

// Agenda (Google Calendar pelo link secreto iCal): scripts/agenda.py a cada 15 min.
// Eventos do mês atual até ~3 meses à frente; usada no painel do calendário (lista + pontinhos nos dias)
// e na minitela (lembrete do próximo evento, via $XDG_RUNTIME_DIR/agenda.json).
// Notificações 2 h, 1 h, 30 min e 10 min antes de cada evento com hora.

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

    // Avisos antes de cada evento com hora: 2 h, 1 h, 30 min e 10 min (notificação na tela; a minitela
    // também mostra). Cada marco avisa uma vez por evento; se o Quickshell iniciar no meio (ex.: 45 min
    // antes), só avisa o marco atual, sem repetir os que já passaram. Eventos de dia inteiro não avisam.
    readonly property var alertMarks: [120, 60, 30, 10]
    property var alerted: ({})
    // 118 → "2 h", 95 → "1 h 35 min", 30 → "30 min"
    function minutesText(mins) {
        const total = Math.max(1, Math.round(mins / 5) * 5 || Math.round(mins));
        const h = Math.floor(total / 60), m = total % 60;
        return h ? (m ? `${h} h ${m} min` : `${h} h`) : `${m} min`;
    }
    function checkAlerts() {
        const now = new Date();
        let changed = false;
        const a = Object.assign({}, alerted);
        for (const e of events) {
            if (e.diaInteiro) continue;
            const mins = (e.start - now) / 60000;
            if (mins <= 0 || mins > alertMarks[0]) continue;
            // o menor marco que ainda não passou (ex.: faltam 45 min → marco de 60)
            const mark = alertMarks.filter(m => mins <= m).pop();
            const key = `${e.titulo}|${e.inicio}|${mark}`;
            if (a[key]) continue;
            // marca este e os maiores (não avisa depois um marco que já passou)
            for (const m of alertMarks)
                if (m >= mark) a[`${e.titulo}|${e.inicio}|${m}`] = true;
            changed = true;
            const when = `${Qt.formatTime(e.start, "HH:mm")}–${Qt.formatTime(e.end, "HH:mm")}`;
            Quickshell.execDetached(["notify-send", "-a", "Agenda", "-i", "x-office-calendar",
                ...(mark <= 10 ? ["-u", "critical"] : []),
                `Em ${mins <= 10 ? Math.max(1, Math.round(mins)) + " min" : minutesText(mins)}: ${e.titulo}`,
                [when, e.local, e.agenda].filter(x => x).join("  ·  ")]);
        }
        if (changed)
            alerted = a;
    }
    Timer {
        running: root.ok
        interval: 30000
        repeat: true
        triggeredOnStart: true
        onTriggered: root.checkAlerts()
    }

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
        // Teste dos avisos: cria um evento falso daqui a N minutos (some na próxima atualização)
        function testar(minutos: int): void {
            const start = new Date(Date.now() + minutos * 60000);
            const ev = { inicio: start.toISOString(), fim: new Date(start.getTime() + 3600000).toISOString(),
                diaInteiro: false, titulo: `Teste (${minutos} min)`, local: "", agenda: "Teste", cor: 0 };
            root.data = Object.assign({}, root.data, { eventos: root.data.eventos.concat([ev]) });
            root.checkAlerts();
        }
    }
}
