// Bloco arredondado usado por todos os itens da barra.
// O que for colocado dentro dele é organizado em linha (Row).
// Também avisa cliques (clicked) e rolagem do mouse (scrolled).

import QtQuick
import qs

Rectangle {
    id: root

    default property alias content: row.data
    property alias spacing: row.spacing
    property alias hovered: mouse.containsMouse
    property int padding: 10
    property bool clickable: false

    signal clicked(var mouse)
    signal scrolled(var wheel)

    implicitWidth: row.implicitWidth + padding * 2
    implicitHeight: Theme.barHeight
    radius: Theme.radius
    color: Theme.base

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        cursorShape: root.clickable ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: event => root.clicked(event)
        onWheel: event => root.scrolled(event)
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 8
    }
}
