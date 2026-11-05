// Bluetooth: desligado / ligado / nome do dispositivo conectado (e bateria dele).
// Clique esquerdo: abre o painel de conexões na aba Bluetooth. Clique direito: abre o blueman.

import QtQuick
import Quickshell
import Quickshell.Bluetooth
import qs

Pill {
    id: root

    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
    readonly property bool powered: adapter?.enabled ?? false
    readonly property var connected: (adapter?.devices.values ?? []).filter(d => d.connected)
    readonly property var first: connected[0] ?? null

    visible: adapter !== null
    clickable: true
    color: hovered || (QuickSettings.open && QuickSettings.tab === "bluetooth") ? Theme.surface1 : Theme.base

    BarText {
        text: !root.powered ? "\u{f00b2}"           // bluetooth desligado
            : root.first ? "\u{f00b1}"              // conectado
            : "\u{f00af}"                           // ligado
        color: !root.powered ? Theme.overlay : root.first ? Theme.blue : Theme.text
    }

    BarText {
        visible: root.first !== null
        width: Math.min(implicitWidth, 140)
        elide: Text.ElideRight
        text: {
            if (!root.first)
                return "";
            const extra = root.connected.length > 1 ? ` +${root.connected.length - 1}` : "";
            const battery = root.first.batteryAvailable ? ` ${Math.round(root.first.battery * 100)}%` : "";
            return root.first.name + battery + extra;
        }
    }

    onClicked: mouse => {
        if (mouse.button === Qt.RightButton)
            Quickshell.execDetached(["blueman-manager"]);
        else
            QuickSettings.toggleTab("bluetooth");
    }
}
