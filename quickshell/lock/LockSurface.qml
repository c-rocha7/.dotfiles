// Visual da tela de bloqueio (um por monitor), no estilo da moldura:
//   wallpaper desfocado + moldura; barra de cima (bloqueado · data · Wi-Fi, bateria, nº de
//   notificações — só o número, nada do conteúdo); relógio grande, foto, nome e senha no centro;
//   mídia tocando embaixo. Avisos: Caps Lock, senha incorreta (o campo "treme").
// Cores do Theme (seguem o wallpaper). preview = prévia sem bloquear (qs ipc call lock previa).

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Networking
import Quickshell.Services.Mpris
import Quickshell.Widgets
import qs
import qs.bar
import qs.frame

Item {
    id: root

    property bool preview: false
    readonly property var wifiDevice: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var wifiNow: wifiDevice?.networks.values.find(n => n.connected) ?? null
    readonly property int notifCount: NotificationService.history.length

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    // Fundo: wallpaper desfocado e escurecido
    Image {
        id: wallpaper
        anchors.fill: parent
        source: Lock.wallpaper !== "" ? "file://" + Lock.wallpaper : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        visible: false
    }
    MultiEffect {
        anchors.fill: parent
        source: wallpaper
        visible: wallpaper.status === Image.Ready
        blurEnabled: true
        blur: 1.0
        blurMax: 64
        brightness: -0.3
    }

    // Moldura (a mesma da área de trabalho)
    FrameShape {
        anchors.fill: parent
        opacity: Theme.frameOpacity
    }

    // ---------- Barra de cima ----------
    Item {
        x: Theme.frameBorder + 6
        width: parent.width - 2 * x
        height: Theme.frameBar

        Row {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8
            BarText { text: "\u{f033e}"; color: Theme.blue }      // cadeado
            BarText { text: "Bloqueado"; color: Theme.subtext }
        }
        BarText {
            anchors.centerIn: parent
            text: Qt.locale().toString(clock.date, "dddd, d 'de' MMMM")
            color: Theme.subtext
        }
        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 14
            BarText {
                visible: root.notifCount > 0
                text: `\u{f009a}  ${root.notifCount}`
                color: Theme.text
            }
            BarText {
                text: !Networking.wifiEnabled ? "\u{f05aa}" : root.wifiNow ? "\u{f0928}" : "\u{f092e}"
                color: root.wifiNow ? Theme.text : Theme.overlay
            }
            BarText {
                visible: Battery.available
                text: `${Battery.icon} ${Battery.percent}%`
                color: Battery.low ? Theme.red : Battery.pluggedIn ? Theme.green : Theme.text
            }
        }
    }

    // ---------- Centro: relógio, foto, nome e senha ----------
    Column {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -30
        spacing: 6

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            ThemedText {
                text: Qt.formatDateTime(clock.date, "HH")
                font.pixelSize: 130
                font.weight: Font.Bold
            }
            ThemedText {
                text: ":"
                font.pixelSize: 130
                font.weight: Font.Bold
                color: Theme.blue
                opacity: clock.date.getSeconds() % 2 === 0 ? 1 : 0.35
                Behavior on opacity { NumberAnimation { duration: 300 } }
            }
            ThemedText {
                text: Qt.formatDateTime(clock.date, "mm")
                font.pixelSize: 130
                font.weight: Font.Bold
                color: Theme.blue
            }
        }

        Item { width: 1; height: 30 }

        ClippingRectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 88
            height: 88
            radius: 44
            color: Theme.base
            border.width: 3
            border.color: Theme.blue

            Image {
                anchors.fill: parent
                source: "file://" + Quickshell.env("HOME") + "/Imagens/Icons/dog-sword.jpg"
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }
        }
        ThemedText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Quickshell.env("USER")
            font.pixelSize: 18
            topPadding: 6
            bottomPadding: 12
        }

        // Campo de senha
        Rectangle {
            id: field
            anchors.horizontalCenter: parent.horizontalCenter
            width: 300
            height: 46
            radius: 23
            color: Theme.island
            border.width: 2
            border.color: Lock.status !== "" ? Theme.red : input.activeFocus ? Theme.blue : Theme.surface1

            Behavior on border.color {
                ColorAnimation { duration: 150 }
            }

            // "Tremida" quando a senha está errada
            transform: Translate { id: shake }
            SequentialAnimation {
                id: shakeAnim
                NumberAnimation { target: shake; property: "x"; to: -10; duration: 50 }
                NumberAnimation { target: shake; property: "x"; to: 10; duration: 70 }
                NumberAnimation { target: shake; property: "x"; to: -6; duration: 60 }
                NumberAnimation { target: shake; property: "x"; to: 0; duration: 50 }
            }
            Connections {
                target: Lock
                function onFailed() {
                    input.text = "";
                    shakeAnim.restart();
                }
            }

            TextInput {
                id: input
                anchors.fill: parent
                anchors.leftMargin: 20
                anchors.rightMargin: 20
                verticalAlignment: TextInput.AlignVCenter
                horizontalAlignment: TextInput.AlignHCenter
                echoMode: TextInput.Password
                passwordCharacter: "●"
                color: Theme.text
                font.family: Theme.font
                font.pixelSize: 16
                focus: true
                enabled: !Lock.busy
                clip: true

                onAccepted: root.preview ? Lock.previewOpen = false : Lock.submit(text)
                onTextChanged: if (text !== "") Lock.status = ""

                Component.onCompleted: forceActiveFocus()

                ThemedText {
                    anchors.centerIn: parent
                    visible: input.text === ""
                    text: Lock.busy ? "Verificando…" : "  Senha"
                    color: Theme.overlay
                    font.pixelSize: 15
                    font.weight: Font.Normal
                }
            }
        }

        // Avisos abaixo do campo
        ThemedText {
            anchors.horizontalCenter: parent.horizontalCenter
            topPadding: 10
            text: Lock.status !== "" ? Lock.status
                : Keyboard.capsLock ? "\u{f0632}  Caps Lock ligado" : " "
            color: Lock.status !== "" ? Theme.red : Theme.blue
            font.pixelSize: 13
        }
    }

    // ---------- Embaixo: mídia tocando ----------
    Rectangle {
        visible: Mpris.players.values.length > 0
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Theme.frameBorder + 40
        width: media.width + 12
        height: media.height + 12
        radius: 16
        color: Theme.island
        opacity: 0.95

        MediaCard {
            id: media
            anchors.centerIn: parent
            width: 380
        }
    }

    // Prévia: Esc fecha
    Keys.onEscapePressed: if (root.preview) Lock.previewOpen = false
}
