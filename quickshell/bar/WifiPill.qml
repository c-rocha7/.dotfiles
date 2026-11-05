// Wi-Fi: ícone do sinal + nome da rede conectada.
// Clique: abre o painel de conexões na aba Wi-Fi.

import QtQuick
import Quickshell.Networking
import qs

Pill {
    id: root

    readonly property var device: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var current: device?.networks.values.find(n => n.connected) ?? null

    visible: device !== null
    clickable: true
    color: hovered || (QuickSettings.open && QuickSettings.tab === "wifi") ? Theme.surface1 : Theme.base

    BarText {
        text: {
            if (!Networking.wifiEnabled)
                return "\u{f05aa}"; // wifi desligado
            if (!root.current)
                return "\u{f092e}"; // sem conexão
            const s = root.current.signalStrength;
            return s > 0.75 ? "\u{f0928}" : s > 0.5 ? "\u{f0925}" : s > 0.25 ? "\u{f0922}" : "\u{f091f}";
        }
        color: !Networking.wifiEnabled || !root.current ? Theme.overlay : Theme.blue
    }

    BarText {
        visible: root.current !== null
        width: Math.min(implicitWidth, 120)
        elide: Text.ElideRight
        text: root.current?.name ?? ""
    }

    onClicked: QuickSettings.toggleTab("wifi")
}
