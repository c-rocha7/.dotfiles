pragma Singleton

// Painel do calendário da moldura (calendário, clima e mídia): aberto/fechado.
// Abre pelo clique na hora ou: qs ipc call calendar toggle

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool open: false

    IpcHandler {
        target: "calendar"

        function toggle(): void { root.open = !root.open; }
        function aberto(): bool { return root.open; }
    }
}
