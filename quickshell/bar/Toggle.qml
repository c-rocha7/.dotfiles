// Interruptor liga/desliga.

import QtQuick
import qs

Rectangle {
    id: root

    property bool checked: false
    signal toggled

    implicitWidth: 40
    implicitHeight: 22
    radius: height / 2
    color: checked ? Theme.blue : Theme.surface1

    Behavior on color {
        ColorAnimation { duration: 150 }
    }

    Rectangle {
        width: 16
        height: 16
        radius: 8
        y: 3
        x: root.checked ? root.width - width - 3 : 3
        color: root.checked ? Theme.base : Theme.text

        Behavior on x {
            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }
}
