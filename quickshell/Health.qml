pragma Singleton

// Saúde do sistema (página "Sistema" da central de controle). Roda scripts/saude.sh quando
// a central está aberta (a cada 10 s) — nada fica rodando com ela fechada.

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool watching: false
    property var data: null
    readonly property bool loaded: data !== null

    // Alertas (vermelho): serviços com falha, disco quase cheio, temperatura alta
    readonly property var alerts: {
        if (!data) return [];
        const a = [];
        for (const f of data.falhas) a.push(`Serviço com falha: ${f}`);
        if (diskPct >= 90) a.push(`Disco ${diskPct}% cheio`);
        if (Number(data.temp.cpu) >= 90) a.push(`CPU a ${data.temp.cpu} °C`);
        if (Number(data.temp.ssd) >= 70) a.push(`SSD a ${data.temp.ssd} °C`);
        return a;
    }
    readonly property int diskPct: data ? Math.round(100 * data.disco.usado / data.disco.total) : 0
    readonly property int memPct: data ? Math.round(100 * (data.memoria.total - data.memoria.livre) / data.memoria.total) : 0
    readonly property string summary: !data ? ""
        : alerts.length ? (alerts.length === 1 ? "1 alerta" : `${alerts.length} alertas`)
        : data.travamentos.length ? `ok · ${data.travamentos.length} travamento${data.travamentos.length > 1 ? "s" : ""}`
        : "tudo ok"

    function gb(bytes) { return (bytes / 1e9).toFixed(bytes < 1e11 ? 1 : 0).replace(".", ","); }
    function refresh() { if (!proc.running) proc.running = true; }

    onWatchingChanged: if (watching) refresh()

    Process {
        id: proc
        command: ["bash", Quickshell.shellPath("scripts/saude.sh")]
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.data = JSON.parse(text); } catch (e) { console.warn("saude.sh:", e); }
            }
        }
    }
    Timer {
        running: root.watching
        interval: 10000
        repeat: true
        onTriggered: root.refresh()
    }
}
