// Painel de notificações (substitui o painel do swaync).
// Abre ao clicar no sino; fecha clicando fora, no sino de novo ou com Esc.

import QtQuick
import qs

IslandView {
    id: root

    readonly property int count: NotificationService.history.length

    padH: 14
    padV: 14

    Column {
        width: 420
        spacing: 10

        // Cabeçalho: título, "não perturbe" e limpar tudo
        Item {
            width: parent.width
            height: 26

            ThemedText {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: root.count > 0 ? `Notificações (${root.count})` : "Notificações"
                font.pixelSize: 15
            }

            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                HeaderButton {
                    icon: NotificationService.dnd ? "\u{f009b}" : "\u{f009a}"
                    active: NotificationService.dnd
                    onClicked: NotificationService.dnd = !NotificationService.dnd
                }
                HeaderButton {
                    icon: "" // lixeira
                    visible: root.count > 0
                    onClicked: NotificationService.clearAll()
                }
            }
        }

        ThemedText {
            visible: root.count === 0
            width: parent.width
            topPadding: 16
            bottomPadding: 16
            horizontalAlignment: Text.AlignHCenter
            text: NotificationService.dnd ? "Nenhuma notificação · não perturbe ligado"
                                          : "Nenhuma notificação"
            color: Theme.overlay
            font.weight: Font.Normal
        }

        // Lista com rolagem (no máximo ~400px de altura)
        Flickable {
            id: flick
            visible: root.count > 0
            width: parent.width
            height: Math.min(cards.implicitHeight, 400)
            contentHeight: cards.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: cards
                width: flick.width
                spacing: 8

                Repeater {
                    model: NotificationService.history

                    NotificationCard {
                        required property var modelData
                        width: cards.width
                        entry: modelData
                    }
                }
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
