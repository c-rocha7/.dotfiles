// Visual da tela de bloqueio (um por monitor):
// wallpaper desfocado, hora e data, foto, nome e campo de senha no estilo da ilha.
// Avisos: Caps Lock ligado, senha incorreta (o campo "treme"), bateria.

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import qs
import qs.bar

Item {
    id: root

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
        brightness: -0.25
    }

    // Topo: pílula estilo ilha com a bateria
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        y: Theme.islandTop
        visible: Battery.available
        width: battery.implicitWidth + 32
        height: Theme.barHeight
        radius: height / 2
        color: Theme.island

        BarText {
            id: battery
            anchors.centerIn: parent
            text: `${Battery.icon} ${Battery.percent}%`
            color: Battery.low ? Theme.red : Battery.pluggedIn ? Theme.green : Theme.text
        }
    }

    // Centro: hora, data, foto, nome e senha
    Column {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -40
        spacing: 6

        ThemedText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(clock.date, "HH:mm")
            font.pixelSize: 110
            font.weight: Font.Bold
        }
        ThemedText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.locale().toString(clock.date, "dddd, d 'de' MMMM")
            color: Theme.subtext
            font.pixelSize: 20
            font.weight: Font.Normal
        }

        Item { width: 1; height: 40 }

        ClippingRectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 96
            height: 96
            radius: 48
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

                onAccepted: Lock.submit(text)
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
}
