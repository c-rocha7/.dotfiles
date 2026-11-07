// Botão da central de controle na barra: só os ícones de Wi-Fi, Bluetooth e volume
// (o estado de relance; os detalhes ficam na central). Clique: abre a central.
// Rolagem: volume ±5%. Clique do meio: muta/desmuta.

import QtQuick
import Quickshell.Bluetooth
import Quickshell.Networking
import Quickshell.Services.Pipewire
import qs
import qs.bar

Pill {
    id: root

    property bool open: false
    readonly property var wifiDevice: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var wifiNow: wifiDevice?.networks.values.find(n => n.connected) ?? null
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool btOn: adapter?.enabled ?? false
    readonly property bool btConnected: (adapter?.devices.values ?? []).some(d => d.connected)
    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property real vol: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false

    PwObjectTracker { objects: [root.sink] }

    clickable: true
    spacing: 10
    color: hovered || open ? Theme.surface1 : Theme.base

    BarText {
        text: {
            if (!Networking.wifiEnabled) return "\u{f05aa}";
            if (!root.wifiNow) return "\u{f092e}";
            const s = root.wifiNow.signalStrength;
            return s > 0.75 ? "\u{f0928}" : s > 0.5 ? "\u{f0925}" : s > 0.25 ? "\u{f0922}" : "\u{f091f}";
        }
        color: Networking.wifiEnabled && root.wifiNow ? Theme.text : Theme.overlay
    }
    BarText {
        visible: root.btOn
        text: root.btConnected ? "\u{f00b1}" : "\u{f00af}"
        color: root.btConnected ? Theme.blue : Theme.text
    }
    BarText {
        text: root.muted ? "\u{f075f}" : root.vol < 0.34 ? "" : root.vol < 0.67 ? "" : ""
        color: root.muted ? Theme.red : Theme.text
    }

    onClicked: mouse => {
        if (mouse.button === Qt.MiddleButton) {
            if (sink?.audio) sink.audio.muted = !sink.audio.muted;
        } else {
            ControlCenter.toggle("main");
        }
    }
    onScrolled: wheel => {
        if (sink?.audio)
            sink.audio.volume = Math.max(0, Math.min(1, sink.audio.volume + (wheel.angleDelta.y > 0 ? 0.05 : -0.05)));
    }
}
