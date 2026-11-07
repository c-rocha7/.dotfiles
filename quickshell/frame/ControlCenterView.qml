// Central de controle (canto direito da moldura).
//   Página principal: botões (Wi-Fi, Bluetooth, Não perturbe, Luz noturna, Microfone, Energia,
//   Modo foco, Conta-gotas, Texto da tela),
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

    // Ferramentas de tela: fecha a central antes (senão ela aparece no print/na seleção)
    function runTool(script) {
        ControlCenter.close();
        Quickshell.execDetached(["bash", "-c", `sleep 0.35; "$HOME/.dotfiles/hypr/scripts/${script}"`]);
    }

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
    Binding { target: Docker; property: "watching"; value: root.shown }
    Binding { target: Health; property: "watching"; value: root.shown }
    Binding { target: GitHub; property: "watching"; value: root.shown }

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
                text: ({ wifi: "Wi-Fi", bluetooth: "Bluetooth", audio: "Áudio", battery: "Bateria", docker: "Docker", health: "Sistema", github: "GitHub" })[root.page] ?? ""
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
                CcTile {
                    icon: "\u{f04fe}"   // alvo
                    label: "Modo foco"
                    sublabel: Focus.on ? "Ligado" : "Desligado"
                    active: Focus.on
                    onToggled: Focus.toggle()
                }
                CcTile {
                    icon: "\u{f020a}"   // conta-gotas
                    label: "Conta-gotas"
                    sublabel: "Copiar uma cor"
                    onToggled: root.runTool("conta-gotas.sh")
                }
                CcTile {
                    icon: "\u{f113a}"   // OCR
                    label: "Texto da tela"
                    sublabel: "Copiar texto"
                    onToggled: root.runTool("texto-da-tela.sh")
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

            // Sistema (clique: saúde do sistema)
            Rectangle {
                width: 352
                height: 34
                radius: 10
                color: sysMouse.containsMouse ? Theme.surface1 : Theme.base

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    spacing: 8
                    BarText {
                        text: "\u{f04c5}"
                        color: Health.alerts.length ? Theme.red : Health.loaded ? Theme.green : Theme.text
                    }
                    BarText { text: "Sistema" }
                    ThemedText {
                        anchors.verticalCenter: parent.verticalCenter
                        font.pixelSize: 12
                        color: Health.alerts.length ? Theme.red : Theme.subtext
                        text: Health.summary
                    }
                }
                BarText {
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    text: ""
                    font.pixelSize: 10
                    color: Theme.subtext
                }
                MouseArea {
                    id: sysMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.go("health")
                }
            }

            // GitHub (clique: notificações e PRs)
            Rectangle {
                width: 352
                height: 34
                radius: 10
                color: ghMouse.containsMouse ? Theme.surface1 : Theme.base

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    spacing: 8
                    BarText { text: "\u{f02a4}"; color: GitHub.pending > 0 ? Theme.blue : Theme.text }
                    BarText { text: "GitHub" }
                    ThemedText {
                        anchors.verticalCenter: parent.verticalCenter
                        font.pixelSize: 12
                        color: Theme.subtext
                        text: !GitHub.data ? "" : !GitHub.ok ? "não configurado"
                            : `${GitHub.notifCount} notificaç${GitHub.notifCount === 1 ? "ão" : "ões"} · ${GitHub.reviewCount} revis${GitHub.reviewCount === 1 ? "ão" : "ões"}`
                    }
                }
                BarText {
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    text: ""
                    font.pixelSize: 10
                    color: Theme.subtext
                }
                MouseArea {
                    id: ghMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.go("github")
                }
            }

            // Docker (clique: containers)
            Rectangle {
                width: 352
                height: 34
                radius: 10
                color: dockMouse.containsMouse ? Theme.surface1 : Theme.base

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    spacing: 8
                    BarText { text: "\u{f0868}"; color: Docker.runningCount > 0 ? Theme.blue : Theme.text }
                    BarText { text: "Docker" }
                    ThemedText {
                        anchors.verticalCenter: parent.verticalCenter
                        font.pixelSize: 12
                        color: Theme.subtext
                        text: !Docker.loaded ? "" : !Docker.daemon ? "parado"
                            : Docker.containers.length === 0 ? "sem containers"
                            : `${Docker.runningCount} rodando de ${Docker.containers.length}`
                    }
                }
                BarText {
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    text: ""
                    font.pixelSize: 10
                    color: Theme.subtext
                }
                MouseArea {
                    id: dockMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.go("docker")
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
        HealthView {
            visible: root.page === "health"
            height: visible ? implicitHeight : 0
        }
        GitHubView {
            visible: root.page === "github"
            height: visible ? implicitHeight : 0
        }
        DockerView {
            visible: root.page === "docker"
            height: visible ? implicitHeight : 0
        }
        BatteryView {
            visible: root.page === "battery"
            height: visible ? implicitHeight : 0
        }
    }
}
