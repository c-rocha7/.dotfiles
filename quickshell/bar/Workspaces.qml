// Workspaces 1 a 5, sempre visíveis.
// Clique: vai para o workspace. Rolagem: anterior/próximo.
// Os comandos usam a sintaxe Lua do Hyprland 0.55+ (hl.dsp.focus).

import QtQuick
import Quickshell.Hyprland
import qs

Row {
    spacing: Theme.gap

    Repeater {
        model: 5

        Pill {
            id: ws

            required property int index
            readonly property int number: index + 1
            readonly property bool active: Hyprland.focusedWorkspace?.id === number

            implicitWidth: 36 // largura fixa, igual à do Waybar
            clickable: true
            color: active ? Theme.blue : (hovered ? Theme.surface1 : Theme.base)

            BarText {
                text: ws.number
                color: ws.active ? Theme.base : Theme.text
            }

            onClicked: Hyprland.dispatch(`hl.dsp.focus({ workspace = ${number} })`)
            onScrolled: wheel => {
                const target = wheel.angleDelta.y > 0 ? "e-1" : "e+1";
                Hyprland.dispatch(`hl.dsp.focus({ workspace = "${target}" })`);
            }
        }
    }
}
