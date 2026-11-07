// Central de controle (canto direito da moldura).
//   Página principal: botões (Wi-Fi, Bluetooth, Não perturbe, Luz noturna, Microfone, Energia),
//   volume e brilho, bateria e mídia.
//   Subpáginas (setinha ›): Wi-Fi, Bluetooth (ConnectionsView), Áudio (AudioView), Bateria.
// A página vem de "page" (ControlCenter.page, ou Wi-Fi/Bluetooth/áudio abertos pelos ícones).

import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Networking
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import qs
import qs.bar

IslandView {
    id: root

    property string page: "main"
    property MprisPlayer player
    padH: 8
    padV: 8

    function go(p) {
        QuickSettings.close();
        Audio.close();
        ControlCenter.show(p);
    }

    readonly property var wifiDevice: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var wifiNow: wifiDevice?.networks.values.find(n => n.connected) ?? null
    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
    readonly property var btNow: (adapter?.devices.values ?? []).find(d => d.connected) ?? null
    readonly property PwNode source: Pipewire.defaultAudioSource
    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink, root.source]
    }
    onShownChanged: if (shown) Brightness.refresh()

    readonly property var profileNames: ({
            [PowerProfile.PowerSaver]: "Economia",
            [PowerProfile.Balanced]: "Equilíbrio",
            [PowerProfile.Performance]: "Desempenho"
        })

    Column {
        spacing: 10

        // Cabeçalho das subpáginas
        Row {
            visible: root.page !== "main"
            spacing: 8
            SmallButton {
                text: "  Voltar"
                onClicked: root.go("main")
            }
            ThemedText {
                anchors.verticalCenter: parent.verticalCenter
                font.bold: true
                text: ({ wifi: "Wi-Fi", bluetooth: "Bluetooth", audio: "Áudio", battery: "Bateria" })[root.page] ?? ""
            }
        }

        // ---------- Página principal ----------
        Column {
            visible: root.page === "main"
            spacing: 10

            Grid {
                columns: 3
                spacing: 8

                CcTile {
                    icon: Networking.wifiEnabled ? "\u{f05a9}" : "\u{f05aa}"
                    label: "Wi-Fi"
                    sublabel: !Networking.wifiEnabled ? "Desligado" : (root.wifiNow?.name ?? "Sem conexão")
                    active: Networking.wifiEnabled
                    hasDetail: true
                    onToggled: Networking.wifiEnabled = !Networking.wifiEnabled
                    onDetail: root.go("wifi")
                }
                CcTile {
                    icon: (root.adapter?.enabled ?? false) ? "\u{f00af}" : "\u{f00b2}"
                    label: "Bluetooth"
                    sublabel: !(root.adapter?.enabled ?? false) ? "Desligado" : (root.btNow?.name ?? "Ligado")
                    active: root.adapter?.enabled ?? false
                    hasDetail: true
                    onToggled: if (root.adapter) root.adapter.enabled = !root.adapter.enabled
                    onDetail: root.go("bluetooth")
                }
                CcTile {
                    icon: NotificationService.dnd ? "\u{f009b}" : "\u{f009a}"
                    label: "Não perturbe"
                    sublabel: NotificationService.dnd ? "Ligado" : "Desligado"
                    active: NotificationService.dnd
                    onToggled: NotificationService.toggleDnd()
                }
                CcTile {
                    icon: "\u{f0594}"   // lua
                    label: "Luz noturna"
                    sublabel: NightLight.on ? `${NightLight.temperature} K` : "Desligada"
                    active: NightLight.on
                    onToggled: NightLight.toggle()
                }
                CcTile {
                    readonly property bool muted: root.source?.audio?.muted ?? false
                    icon: muted ? "" : ""
                    label: "Microfone"
                    sublabel: muted ? "Mudo" : "Ligado"
                    active: !muted
                    onToggled: if (root.source?.audio) root.source.audio.muted = !root.source.audio.muted
                }
                CcTile {
                    icon: "\u{f06a5}"
                    label: "Energia"
                    sublabel: root.profileNames[PowerProfiles.profile] ?? ""
                    active: PowerProfiles.profile === PowerProfile.Performance
                    hasDetail: true
                    onToggled: {
                        const order = [PowerProfile.PowerSaver, PowerProfile.Balanced];
                        if (PowerProfiles.hasPerformanceProfile)
                            order.push(PowerProfile.Performance);
                        PowerProfiles.profile = order[(order.indexOf(PowerProfiles.profile) + 1) % order.length];
                    }
                    onDetail: root.go("battery")
                }
            }

            Row {
                spacing: 0
                VolumeSlider { node: Pipewire.defaultAudioSink; trackWidth: 230 }
                SmallButton {
                    anchors.verticalCenter: parent.verticalCenter
                    text: ""
                    onClicked: root.go("audio")
                }
            }
            BrightnessSlider { trackWidth: 230 }

            // Bateria (clique: detalhes)
            Rectangle {
                width: 352
                height: 34
                radius: 10
                color: batMouse.containsMouse ? Theme.surface1 : Theme.base

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    spacing: 8
                    BarText { text: Battery.icon; color: Battery.low ? Theme.red : Theme.text }
                    BarText { text: `${Battery.percent}%` }
                    ThemedText {
                        anchors.verticalCenter: parent.verticalCenter
                        font.pixelSize: 12
                        color: Theme.subtext
                        text: Battery.pluggedIn ? "na tomada" : "na bateria"
                    }
                }
                BarText {
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    text: ""
                    font.pixelSize: 10
                    color: Theme.subtext
                }
                MouseArea {
                    id: batMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.go("battery")
                }
            }

            // Mídia
            Rectangle {
                visible: root.player !== null
                width: 352
                height: Theme.barHeight + 4
                radius: 10
                color: Theme.base
                MediaRow {
                    anchors.centerIn: parent
                    player: root.player
                    maxTextWidth: 230
                }
            }
        }

        // ---------- Subpáginas ----------
        Item {
            visible: root.page === "wifi" || root.page === "bluetooth"
            width: visible ? connections.implicitWidth : 0
            height: visible ? connections.implicitHeight : 0
            ConnectionsView {
                id: connections
                shown: root.shown && (root.page === "wifi" || root.page === "bluetooth")
            }
        }
        Item {
            visible: root.page === "audio"
            width: visible ? audio.implicitWidth : 0
            height: visible ? audio.implicitHeight : 0
            AudioView {
                id: audio
                shown: root.shown && root.page === "audio"
            }
        }
        BatteryView {
            visible: root.page === "battery"
            height: visible ? implicitHeight : 0
        }
    }
}
