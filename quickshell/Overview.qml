pragma Singleton

// Visão geral das workspaces (estilo niri/macOS): aberta/fechada.
// SUPER+Tab ou 3 dedos para cima no touchpad; também: qs ipc call overview toggle

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool open: false
    property string query: ""            // busca de janelas (digitar com a visão geral aberta)

    function toggle() { open = !open; }
    function close() { open = false; }

    IpcHandler {
        target: "overview"

        function toggle(): void { root.toggle(); }
        function open(): void { root.open = true; }
        function close(): void { root.close(); }
        // Abre já buscando: qs ipc call overview buscar zen
        function buscar(texto: string): void {
            root.open = true;
            root.query = texto;
        }
    }
}
