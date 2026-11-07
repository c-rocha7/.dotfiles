// Página do Docker (central de controle): containers com estado, imagem e portas.
// Botões: ▶ iniciar / ■ parar, ↻ reiniciar, logs (terminal), shell (terminal).

import QtQuick
import qs
import qs.bar

Column {
    id: root

    width: 352
    spacing: 8

    // Docker parado
    Column {
        visible: Docker.loaded && !Docker.daemon
        spacing: 8
        ThemedText {
            text: "O Docker está parado."
            color: Theme.subtext
        }
        SmallButton {
            text: "  Iniciar o Docker"
            onClicked: Docker.startDaemon()
        }
    }

    ThemedText {
        visible: Docker.daemon && Docker.containers.length === 0
        text: "Nenhum container. Crie com docker run / docker compose up."
        font.pixelSize: 12
        color: Theme.subtext
        width: parent.width
        wrapMode: Text.WordWrap
    }

    Flickable {
        visible: Docker.containers.length > 0
        width: parent.width
        height: Math.min(list.implicitHeight, 360)
        contentHeight: list.implicitHeight
        clip: true

        Column {
            id: list
            width: parent.width
            spacing: 6

            Repeater {
                model: Docker.containers

                Rectangle {
                    id: row
                    required property var modelData
                    readonly property bool up: modelData.state === "running"
                    readonly property bool busy: Docker.busy === modelData.name

                    width: list.width
                    height: 54
                    radius: 10
                    color: Theme.base

                    Rectangle {      // bolinha do estado
                        x: 10
                        anchors.verticalCenter: parent.verticalCenter
                        width: 8
                        height: 8
                        radius: 4
                        color: row.up ? Theme.green : row.modelData.state === "exited" ? Theme.overlay : Theme.yellow
                    }
                    Column {
                        x: 26
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 26 - buttons.width - 10
                        ThemedText {
                            width: parent.width
                            elide: Text.ElideRight
                            text: row.modelData.name
                            font.bold: true
                        }
                        ThemedText {
                            width: parent.width
                            elide: Text.ElideRight
                            font.pixelSize: 11
                            color: Theme.subtext
                            text: [row.modelData.image, row.up ? row.modelData.ports : row.modelData.status]
                                .filter(x => x).join("  ·  ")
                        }
                    }
                    Row {
                        id: buttons
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2
                        opacity: row.busy ? 0.4 : 1
                        enabled: !row.busy

                        SmallButton {
                            text: row.up ? "\u{f04db}" : "\u{f040a}"   // parar / iniciar
                            onClicked: Docker.act(row.modelData.name, row.up ? "stop" : "start")
                        }
                        SmallButton {
                            visible: row.up
                            text: "\u{f0450}"                        // reiniciar
                            onClicked: Docker.act(row.modelData.name, "restart")
                        }
                        SmallButton {
                            text: "\u{f0219}"                        // logs
                            onClicked: Docker.logs(row.modelData.name)
                        }
                        SmallButton {
                            visible: row.up
                            text: "\u{f018d}"                        // terminal
                            onClicked: Docker.shell(row.modelData.name)
                        }
                    }
                }
            }
        }
    }
}
