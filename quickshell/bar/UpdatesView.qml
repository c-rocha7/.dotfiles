// Painel de atualizações (abre ao clicar na UpdatesPill; mesmo estilo da central de notificações).
// Lista os pacotes por origem (sistema, AUR, Flatpak) com a versão atual → nova.
// Cabeçalho: conferir de novo. Rodapé: "Atualizar tudo" (abre o terminal com o "atualizar").

import QtQuick
import qs

IslandView {
    id: root

    readonly property var sections: [
        { key: "repo", title: "Sistema", icon: "\u{f08c7}", color: Theme.blue },
        { key: "aur", title: "AUR", icon: "\u{f0bc0}", color: Theme.yellow },
        { key: "flatpak", title: "Flatpak", icon: "\u{f03d6}", color: Theme.green },
    ]
    property var collapsed: ({})       // origem → true quando a seção está recolhida

    padH: 14
    padV: 14

    Column {
        width: 420
        spacing: 10

        // Cabeçalho: título, última conferência e botão de conferir de novo
        Item {
            width: parent.width
            height: 26

            Column {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                ThemedText {
                    text: Updates.count > 0 ? `Atualizações (${Updates.count})` : "Atualizações"
                    font.pixelSize: 15
                }
            }

            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                ThemedText {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: !isNaN(Updates.lastCheck.getTime())
                    text: Updates.checking ? "conferindo…"
                                           : "conferido às " + Qt.formatDateTime(Updates.lastCheck, "HH:mm")
                    font.pixelSize: 11
                    font.weight: Font.Normal
                    color: Theme.overlay
                }
                HeaderButton {
                    icon: "\u{f0450}"   // conferir de novo
                    active: Updates.checking
                    onClicked: Updates.check()
                }
            }
        }

        ThemedText {
            visible: Updates.count === 0
            width: parent.width
            topPadding: 16
            bottomPadding: 16
            horizontalAlignment: Text.AlignHCenter
            text: Updates.checking ? "Conferindo atualizações…" : "Tudo atualizado"
            color: Theme.overlay
            font.weight: Font.Normal
        }

        // Lista com rolagem (no máximo ~420px de altura)
        Flickable {
            id: flick
            visible: Updates.count > 0
            width: parent.width
            height: Math.min(list.implicitHeight, 420)
            contentHeight: list.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: list
                width: flick.width
                spacing: 10

                Repeater {
                    model: root.sections

                    Column {
                        id: section
                        required property var modelData
                        readonly property var items: Updates.packages.filter(p => p.source === modelData.key)
                        readonly property bool open: root.collapsed[modelData.key] !== true
                        visible: items.length > 0
                        width: list.width
                        spacing: 4

                        // Cabeçalho da seção: ícone + nome + quantidade; clique recolhe
                        Rectangle {
                            width: parent.width
                            height: 24
                            radius: 6
                            color: headMouse.containsMouse ? Theme.surface0 : "transparent"

                            Row {
                                anchors.left: parent.left
                                anchors.leftMargin: 4
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 6
                                ThemedText {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: section.modelData.icon
                                    color: section.modelData.color
                                }
                                ThemedText {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: section.modelData.title
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: Theme.subtext
                                }
                                ThemedText {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: section.items.length
                                    font.pixelSize: 11
                                    color: Theme.overlay
                                }
                            }
                            ThemedText {
                                anchors.right: parent.right
                                anchors.rightMargin: 6
                                anchors.verticalCenter: parent.verticalCenter
                                text: section.open ? "" : ""
                                font.pixelSize: 11
                                color: Theme.overlay
                            }
                            MouseArea {
                                id: headMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    const c = Object.assign({}, root.collapsed);
                                    c[section.modelData.key] = section.open;
                                    root.collapsed = c;
                                }
                            }
                        }

                        // Pacotes: nome à esquerda, versões à direita
                        Rectangle {
                            visible: section.open
                            width: parent.width
                            height: rows.implicitHeight + 12
                            radius: 8
                            color: Theme.base

                            Column {
                                id: rows
                                x: 10
                                y: 6
                                width: parent.width - 20

                                Repeater {
                                    model: section.items

                                    Item {
                                        required property var modelData
                                        width: rows.width
                                        height: 24

                                        ThemedText {
                                            id: pkgName
                                            anchors.left: parent.left
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: Math.min(implicitWidth, parent.width - versions.implicitWidth - 12)
                                            elide: Text.ElideRight
                                            text: modelData.name
                                            font.pixelSize: 13
                                        }
                                        Row {
                                            id: versions
                                            anchors.right: parent.right
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: 6
                                            ThemedText {
                                                anchors.verticalCenter: parent.verticalCenter
                                                visible: modelData.from !== ""
                                                text: modelData.from
                                                font.pixelSize: 11
                                                font.weight: Font.Normal
                                                color: Theme.overlay
                                            }
                                            ThemedText {
                                                anchors.verticalCenter: parent.verticalCenter
                                                visible: modelData.from !== ""
                                                text: ""   // seta
                                                font.pixelSize: 10
                                                color: Theme.overlay
                                            }
                                            ThemedText {
                                                anchors.verticalCenter: parent.verticalCenter
                                                visible: modelData.to !== ""
                                                text: modelData.to
                                                font.pixelSize: 11
                                                color: section.modelData.color
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Rodapé: atualizar tudo
        Rectangle {
            visible: Updates.count > 0
            width: parent.width
            height: 32
            radius: 8
            color: runMouse.containsMouse ? Theme.blue : Theme.base

            ThemedText {
                anchors.centerIn: parent
                text: "\u{f03d7}  Atualizar tudo"
                color: runMouse.containsMouse ? Theme.base : Theme.text
            }
            MouseArea {
                id: runMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Updates.run()
            }
        }
    }

    component HeaderButton: Rectangle {
        id: button

        property string icon
        property bool active: false
        signal clicked

        width: 26
        height: 26
        radius: 8
        color: active ? Theme.blue : mouse.containsMouse ? Theme.surface1 : Theme.base

        ThemedText {
            anchors.centerIn: parent
            text: button.icon
            color: button.active ? Theme.base : Theme.text
        }
        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: button.clicked()
        }
    }
}
