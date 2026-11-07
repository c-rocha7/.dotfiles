// Painel de notificações (substitui o painel do swaync).
// Abre ao clicar no sino; fecha clicando fora, no sino de novo ou com Esc.
// Agrupadas por app (o app mais recente em cima): mostra as 2 últimas; "+N" expande o grupo.

import QtQuick
import qs

IslandView {
    id: root

    readonly property int count: NotificationService.history.length
    // Grupos por app, na ordem da notificação mais recente de cada um.
    readonly property var groups: {
        const out = [];
        for (const e of NotificationService.history) {
            const app = e.n?.appName || "Sistema";
            let g = out.find(x => x.app === app);
            if (!g) out.push(g = { app: app, entries: [] });
            g.entries.push(e);
        }
        return out;
    }
    property var expanded: ({})        // app → true quando o grupo está aberto

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
                    model: root.groups

                    Column {
                        id: group
                        required property var modelData
                        readonly property bool open: root.expanded[modelData.app] === true
                        readonly property var shownEntries: open ? modelData.entries : modelData.entries.slice(0, 2)
                        width: cards.width
                        spacing: 6

                        // Cabeçalho do grupo: ícone + app + quantidade, expandir e limpar
                        Item {
                            width: parent.width
                            height: 22
                            Row {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 6
                                Image {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 16
                                    height: 16
                                    sourceSize: Qt.size(32, 32)
                                    source: NotificationService.iconFor(group.modelData.entries[0].n)
                                }
                                ThemedText {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: group.modelData.app
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: Theme.subtext
                                }
                                ThemedText {
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: group.modelData.entries.length > 1
                                    text: group.modelData.entries.length
                                    font.pixelSize: 11
                                    color: Theme.overlay
                                }
                            }
                            Row {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 4
                                HeaderButton {
                                    visible: group.modelData.entries.length > 2
                                    width: 40
                                    height: 20
                                    icon: group.open ? "\uf077" : `+${group.modelData.entries.length - 2}`
                                    onClicked: {
                                        const e = Object.assign({}, root.expanded);
                                        e[group.modelData.app] = !group.open;
                                        root.expanded = e;
                                    }
                                }
                                HeaderButton {
                                    width: 20
                                    height: 20
                                    icon: "\uf00d"   // limpar o grupo
                                    onClicked: { for (const e of group.modelData.entries.slice()) e.n.dismiss(); }
                                }
                            }
                        }
                        Repeater {
                            model: group.shownEntries
                            NotificationCard {
                                required property var modelData
                                width: cards.width
                                entry: modelData
                            }
                        }
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
