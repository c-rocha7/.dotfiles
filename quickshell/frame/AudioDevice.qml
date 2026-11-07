// Um dispositivo de áudio (saída ou entrada) na lista do painel. Clique: vira o padrão.

import QtQuick
import Quickshell.Services.Pipewire
import qs
import qs.bar

Rectangle {
    id: root

    required property PwNode node
    property bool selected: false
    signal clicked

    width: parent?.width ?? 300
    height: 30
    radius: 8
    color: selected ? Theme.base : mouse.containsMouse ? Theme.surface1 : "transparent"

    Row {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 10
        spacing: 8

        BarText {
            text: root.selected ? "\u{f0133}" : "\u{f0130}"   // círculo marcado / vazio
            color: root.selected ? Theme.blue : Theme.overlay
        }
        BarText {
            width: root.width - 50
            elide: Text.ElideRight
            text: root.node?.description || root.node?.nickname || root.node?.name || "?"
            color: root.selected ? Theme.text : Theme.subtext
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
