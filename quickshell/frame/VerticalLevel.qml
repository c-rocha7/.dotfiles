// Aviso vertical da borda direita (volume, brilho): ícone, barrinha vertical e porcentagem.

import QtQuick
import qs
import qs.bar

IslandView {
    id: root

    property string icon
    property real value: 0      // 0–1
    property bool dim: false
    padH: 6
    padV: 8

    Column {
        spacing: 8

        BarText {
            anchors.verticalCenter: undefined
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.icon
            color: root.dim ? Theme.red : Theme.text
        }
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 6
            height: 130
            radius: 3
            color: Theme.surface1
            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: parent.height * Math.max(0, Math.min(1, root.value))
                radius: 3
                color: root.dim ? Theme.overlay : Theme.blue
                Behavior on height { NumberAnimation { duration: 120 } }
            }
        }
        ThemedText {
            anchors.horizontalCenter: parent.horizontalCenter
            font.pixelSize: 11
            text: Math.round(root.value * 100) + "%"
        }
    }
}
