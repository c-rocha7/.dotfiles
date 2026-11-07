// Controle de brilho da tela (mesma escala dos atalhos: 0% = mínimo útil da tela).
// Arrasto/clique/rolagem; manda para o brightness.sh no máximo a cada 80 ms.

import QtQuick
import qs
import qs.bar

Row {
    id: root

    property int trackWidth: 230
    property real value: Brightness.value
    spacing: 8
    height: 28

    Timer {
        id: debounce
        interval: 80
        onTriggered: Brightness.set(root.value * 100)
    }
    function setValue(v) {
        value = Math.max(0, Math.min(1, v));
        debounce.restart();
    }
    Connections {
        target: Brightness
        function onUpdated() { if (!drag.pressed) root.value = Brightness.value; }
    }

    Item {
        width: 28
        height: 28
        BarText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "\u{f00df}"   // sol
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
                width: parent.width * root.value
                height: parent.height
                radius: 3
                color: Theme.blue
            }
        }
        Rectangle {
            visible: drag.containsMouse || drag.pressed
            x: parent.width * root.value - width / 2
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
            onPressed: m => root.setValue(m.x / width)
            onPositionChanged: m => { if (pressed) root.setValue(m.x / width); }
            onWheel: w => root.setValue(root.value + (w.angleDelta.y > 0 ? 0.05 : -0.05))
        }
    }

    BarText {
        width: 40
        horizontalAlignment: Text.AlignRight
        text: Math.round(root.value * 100) + "%"
    }
}
