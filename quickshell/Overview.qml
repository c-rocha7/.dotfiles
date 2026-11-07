pragma Singleton

// Visão geral das workspaces (estilo niri/macOS): aberta/fechada.
// SUPER+Tab ou 3 dedos para cima no touchpad; também: qs ipc call overview toggle

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool open: false

    function toggle() { open = !open; }
    function close() { open = false; }

    IpcHandler {
        target: "overview"

        function toggle(): void { root.toggle(); }
        function open(): void { root.open = true; }
        function close(): void { root.close(); }
    }
}
