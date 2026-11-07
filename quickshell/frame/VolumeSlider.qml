// Controle de volume de um nó do PipeWire (dispositivo ou app):
// ícone (clique: muta) · trilho (clique/arrasto: ajusta; rolagem: ±5%) · porcentagem.

import QtQuick
import Quickshell.Services.Pipewire
import qs
import qs.bar

Row {
    id: root

    property PwNode node
    property string icon: ""
    property int trackWidth: 210

    readonly property bool muted: node?.audio?.muted ?? false
    readonly property real value: node?.audio?.volume ?? 0

    spacing: 8
    height: 28

    function setVolume(v) {
        if (node?.audio)
            node.audio.volume = Math.max(0, Math.min(1, v));
    }

    Rectangle {
        width: 28
        height: 28
        radius: 7
        color: muteMouse.containsMouse ? Theme.surface1 : "transparent"

        BarText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.muted ? "\u{f075f}" : root.icon
            color: root.muted ? Theme.red : Theme.text
        }
        MouseArea {
            id: muteMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: if (root.node?.audio) root.node.audio.muted = !root.node.audio.muted
        }
    }

    Item {
        width: root.trackWidth
        height: 28

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: 6
            radius: 3
            color: Theme.surface1

            Rectangle {
                width: parent.width * Math.min(1, root.value)
                height: parent.height
                radius: 3
                color: root.muted ? Theme.overlay : Theme.blue
            }
        }
        Rectangle {
            visible: drag.containsMouse || drag.pressed
            x: parent.width * Math.min(1, root.value) - width / 2
            anchors.verticalCenter: parent.verticalCenter
            width: 12
            height: 12
            radius: 6
            color: Theme.text
        }
        MouseArea {
            id: drag
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onPressed: m => root.setVolume(m.x / width)
            onPositionChanged: m => { if (pressed) root.setVolume(m.x / width); }
            onWheel: w => root.setVolume(root.value + (w.angleDelta.y > 0 ? 0.05 : -0.05))
        }
    }

    BarText {
        width: 40
        horizontalAlignment: Text.AlignRight
        text: Math.round(root.value * 100) + "%"
        color: root.muted ? Theme.overlay : Theme.text
    }
}
