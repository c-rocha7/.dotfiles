// Seta do cabeçalho do calendário (‹ ou ›).

import QtQuick
import qs

Rectangle {
    id: button

    property string text
    signal clicked

    width: 22
    height: 22
    radius: 6
    color: mouse.containsMouse ? Theme.surface1 : "transparent"

    ThemedText {
        anchors.centerIn: parent
        text: button.text
        color: mouse.containsMouse ? Theme.text : Theme.subtext
        font.pixelSize: 10
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: button.clicked()
    }
}
