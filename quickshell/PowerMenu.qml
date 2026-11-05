pragma Singleton

// Menu de energia que sai da ilha (substitui o wlogout).
// - actions: lista de ações, usada também pelo launcher (buscar "desligar", "bloquear"...)
//   confirm: true pede um segundo clique/Enter antes de executar
//
//   qs ipc call power toggle   abre/fecha o menu

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool open: false

    readonly property var actions: [
        { id: "lock", name: "Bloquear", desc: "Bloqueia a tela", glyph: "",
          keywords: "lock bloquear tela", confirm: false, cmd: "loginctl lock-session" },
        { id: "suspend", name: "Suspender", desc: "Suspende o computador", glyph: "\u{f04b2}",
          keywords: "suspend sleep dormir suspender", confirm: false, cmd: "systemctl suspend" },
        { id: "logout", name: "Sair", desc: "Encerra a sessão do Hyprland", glyph: "\u{f0343}",
          keywords: "logout exit sair sessão", confirm: true,
          cmd: "command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'" },
        { id: "reboot", name: "Reiniciar", desc: "Reinicia o computador", glyph: "\u{f0709}",
          keywords: "reboot restart reiniciar", confirm: true, cmd: "systemctl reboot" },
        { id: "poweroff", name: "Desligar", desc: "Desliga o computador", glyph: "",
          keywords: "shutdown poweroff desligar", confirm: true, cmd: "systemctl poweroff" }
    ]

    function run(action) {
        open = false;
        Quickshell.execDetached(["bash", "-c", action.cmd]);
    }

    function show() {
        Launcher.close();
        NotificationService.centerOpen = false;
        QuickSettings.close();
        Cheatsheet.close();
        Recorder.pickerOpen = false;
        Wallpaper.close();
        open = true;
    }

    function close() {
        open = false;
    }

    IpcHandler {
        target: "power"

        function toggle(): void {
            if (root.open)
                root.close();
            else
                root.show();
        }
    }
}
