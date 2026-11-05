pragma Singleton

// Estado do painel "Conexões" (Wi-Fi e Bluetooth) que sai da ilha.
//   qs ipc call network toggle      abre/fecha (na aba atual)
//   qs ipc call network wifi        abre na aba Wi-Fi
//   qs ipc call network bluetooth   abre na aba Bluetooth

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool open: false
    property string tab: "wifi" // "wifi" ou "bluetooth"

    function show(newTab) {
        tab = newTab;
        Launcher.close();
        NotificationService.centerOpen = false;
        PowerMenu.close();
        Cheatsheet.close();
        Recorder.pickerOpen = false;
        Wallpaper.close();
        open = true;
    }

    function close() {
        open = false;
    }

    // Clique no bloco: abre na aba; se já estiver aberto nela, fecha.
    function toggleTab(newTab) {
        if (open && tab === newTab)
            close();
        else
            show(newTab);
    }

    IpcHandler {
        target: "network"

        function toggle(): void {
            if (root.open)
                root.close();
            else
                root.show(root.tab);
        }
        function wifi(): void { root.show("wifi"); }
        function bluetooth(): void { root.show("bluetooth"); }
    }
}
