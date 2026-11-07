pragma Singleton

// Painel de áudio da moldura (as funções do pavucontrol): aberto/fechado.
// Abre pelo clique no volume da barra ou: qs ipc call audio toggle

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool open: false

    function toggle() { open = !open; }
    function close() { open = false; }

    IpcHandler {
        target: "audio"

        function toggle(): void { root.toggle(); }
    }
}
