pragma Singleton

// Central de controle da moldura: aberta/fechada e qual página.
//   main (botões e controles) · wifi · bluetooth · audio (pavucontrol) · battery
// Abre pelos ícones de status da barra ou: qs ipc call control toggle | qs ipc call control mostrar wifi

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool open: false
    property string page: "main"

    function show(p) {
        page = p || "main";
        if (page === "wifi" || page === "bluetooth")
            QuickSettings.tab = page;        // as telas de Wi-Fi/Bluetooth leem a aba daqui
        open = true;
    }
    function toggle(p) {
        if (open && page === (p || "main"))
            open = false;
        else
            show(p);
    }
    function close() { open = false; }

    IpcHandler {
        target: "control"

        function toggle(): void { root.toggle("main"); }
        function mostrar(nome: string): void { root.show(nome); }
    }
}
