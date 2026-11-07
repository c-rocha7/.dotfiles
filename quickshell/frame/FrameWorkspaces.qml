// Workspaces 1 a 5 da moldura, com os ícones dos apps abertos em cada uma (até 3).
// Clique: vai para a workspace. Rolagem: anterior/próxima.

import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs
import qs.bar

Row {
    spacing: Theme.gap

    Repeater {
        model: 5

        Pill {
            id: ws

            required property int index
            readonly property int number: index + 1
            readonly property bool active: Hyprland.focusedWorkspace?.id === number
            readonly property var apps: Hyprland.toplevels.values
                .filter(t => t.workspace?.id === number)
                .map(t => t.wayland?.appId || t.lastIpcObject?.class || "")
                .filter((a, i, all) => a !== "" && all.indexOf(a) === i)
                .slice(0, 3)

            padding: apps.length ? 10 : 13      // sem apps: mesma largura de antes (36 px)
            clickable: true
            spacing: 6
            color: active ? Theme.blue : (hovered ? Theme.surface1 : Theme.base)

            BarText {
                id: label
                text: ws.number
                color: ws.active ? Theme.base : Theme.text
            }
            Repeater {
                model: ws.apps
                Image {
                    required property string modelData
                    anchors.verticalCenter: parent.verticalCenter
                    width: 16
                    height: 16
                    sourceSize: Qt.size(32, 32)
                    source: Quickshell.iconPath(DesktopEntries.heuristicLookup(modelData)?.icon ?? modelData, "application-x-executable")
                }
            }

            onClicked: Hyprland.dispatch(`hl.dsp.focus({ workspace = ${number} })`)
            onScrolled: wheel => {
                const target = wheel.angleDelta.y > 0 ? "e-1" : "e+1";
                Hyprland.dispatch(`hl.dsp.focus({ workspace = "${target}" })`);
            }
        }
    }
}
