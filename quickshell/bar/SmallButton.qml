// Botão pequeno com texto e/ou ícone (ex.: "Desconectar", lixeira).

import QtQuick
import qs

Rectangle {
    id: root

    property string text
    property color hoverColor: Theme.blue
    signal clicked

    implicitWidth: label.implicitWidth + 16
    implicitHeight: 24
    radius: 7
    color: mouse.containsMouse ? hoverColor : Theme.island

    ThemedText {
        id: label
        anchors.centerIn: parent
        text: root.text
        color: mouse.containsMouse ? Theme.base : Theme.text
        font.pixelSize: 11
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
