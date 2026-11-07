pragma Singleton

// Modo foco: liga o Não perturbe, faz a minitela ignorar notificações (arquivo
// $XDG_RUNTIME_DIR/modo-foco, lido pelo minitela.py) e esconde o Discord/Ferdium numa workspace
// especial ("foco"). Desligar devolve tudo como estava (o Não perturbe volta ao estado anterior
// e as janelas voltam para a workspace 5).
// Central de controle, SUPER+SHIFT+F ou: qs ipc call foco toggle

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool on: false
    property bool dndBefore: false
    readonly property string flag: Quickshell.env("XDG_RUNTIME_DIR") + "/modo-foco"
    readonly property string chats: "^(vesktop|Vesktop|Ferdium|ferdium|org\\.ferdium\\.Ferdium)$"

    function toggle() {
        if (!on) {
            dndBefore = NotificationService.dnd;
            NotificationService.dnd = true;
            Quickshell.execDetached(["bash", "-c", `touch "${flag}"
                for a in $(hyprctl clients -j | jq -r --arg c '${chats}' '.[] | select(.class | test($c)) | .address'); do
                    hyprctl dispatch "hl.dsp.window.move({ workspace = \\"special:foco\\", follow = false, window = \\"address:$a\\" })"
                done`]);
        } else {
            NotificationService.dnd = dndBefore;
            Quickshell.execDetached(["bash", "-c", `rm -f "${flag}"
                for a in $(hyprctl clients -j | jq -r '.[] | select(.workspace.name == "special:foco") | .address'); do
                    hyprctl dispatch "hl.dsp.window.move({ workspace = 5, follow = false, window = \\"address:$a\\" })"
                done`]);
        }
        on = !on;
    }

    // Se o Quickshell reiniciar com o modo ligado, recupera o estado pelo arquivo
    Component.onCompleted: checker.running = true
    Process {
        id: checker
        command: ["test", "-e", root.flag]
        onExited: code => root.on = code === 0
    }

    IpcHandler {
        target: "foco"
        function toggle(): void { root.toggle(); }
    }
}
