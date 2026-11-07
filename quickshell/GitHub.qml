pragma Singleton

// GitHub (barra + página da central): notificações, suas PRs abertas e revisões pedidas.
// Busca a cada 5 min (e ao abrir a central) pelo gh já logado: scripts/github.sh.

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var data: null
    property bool watching: false
    readonly property bool ok: data?.ok === true
    readonly property int notifCount: ok ? data.notificacoes.length : 0
    readonly property int reviewCount: ok ? data.revisar.length : 0
    readonly property int pending: notifCount + reviewCount

    function refresh() { if (!proc.running) proc.running = true; }
    function open(url) {
        Quickshell.execDetached(["xdg-open", url]);
        ControlCenter.close();
    }

    onWatchingChanged: if (watching) refresh()

    Process {
        id: proc
        command: ["bash", Quickshell.shellPath("scripts/github.sh")]
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.data = JSON.parse(text); } catch (e) { console.warn("github.sh:", e); }
            }
        }
    }
    Timer {
        running: true
        triggeredOnStart: true
        interval: 5 * 60 * 1000
        repeat: true
        onTriggered: root.refresh()
    }

    IpcHandler {
        target: "github"
        function atualizar(): void { root.refresh(); }
    }
}
