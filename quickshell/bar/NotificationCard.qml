// Uma notificação no painel: ícone, app · hora, título, texto, botões de ação e "x".
// Clique no cartão: ação padrão do app (se houver).

import QtQuick
import Quickshell.Services.Notifications
import qs

Rectangle {
    id: root

    property var entry // { n: Notification, time: Date }
    readonly property Notification n: entry?.n ?? null

    implicitHeight: content.implicitHeight + 20
    radius: 12
    color: mouse.containsMouse ? Theme.surface1 : Theme.base

    Behavior on color {
        ColorAnimation { duration: 120 }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: if (root.n) NotificationService.invokeDefault(root.n)
    }

    Row {
        id: content
        x: 10
        y: 10
        width: parent.width - 20
        spacing: 10

        NotifIcon {
            notification: root.n
            size: 34
        }

        Column {
            width: parent.width - 34 - 20 - parent.spacing * 2
            spacing: 3

            ThemedText {
                width: parent.width
                elide: Text.ElideRight
                text: (root.n?.appName || "Notificação") + "  ·  " + Qt.formatDateTime(root.entry?.time, "HH:mm")
                color: Theme.overlay
                font.pixelSize: 11
            }
            ThemedText {
                width: parent.width
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
                text: root.n?.summary ?? ""
                color: root.n?.urgency === NotificationUrgency.Critical ? Theme.red : Theme.text
            }
            ThemedText {
                visible: text !== ""
                width: parent.width
                wrapMode: Text.Wrap
                maximumLineCount: 3
                elide: Text.ElideRight
                text: root.n?.body ?? ""
                color: Theme.subtext
                font.pixelSize: 12
                font.weight: Font.Normal
            }

            // Botões de ação do app (a ação "default" é o clique no cartão)
            Flow {
                width: parent.width
                spacing: 6
                topPadding: 4
                visible: actionsRepeater.count > 0

                Repeater {
                    id: actionsRepeater
                    model: Array.from(root.n?.actions ?? []).filter(a => a.identifier !== "default" && a.text !== "")

                    Rectangle {
                        required property var modelData

                        width: label.implicitWidth + 16
                        height: 22
                        radius: 6
                        color: actionMouse.containsMouse ? Theme.blue : Theme.island

                        ThemedText {
                            id: label
                            anchors.centerIn: parent
                            text: parent.modelData.text
                            color: actionMouse.containsMouse ? Theme.base : Theme.text
                            font.pixelSize: 11
                        }
                        MouseArea {
                            id: actionMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: parent.modelData.invoke()
                        }
                    }
                }
            }
        }

        // Dispensar
        ThemedText {
            width: 20
            horizontalAlignment: Text.AlignHCenter
            text: ""
            color: closeMouse.containsMouse ? Theme.red : Theme.overlay
            font.pixelSize: 12

            MouseArea {
                id: closeMouse
                anchors.fill: parent
                anchors.margins: -4
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.n?.dismiss()
            }
        }
    }
}
