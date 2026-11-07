// Botão da central de controle: ícone, nome e estado. Clique: liga/desliga.
// Com "hasDetail", uma setinha à direita abre a página de detalhes.

import QtQuick
import qs
import qs.bar

Rectangle {
    id: root

    property string icon
    property string label
    property string sublabel
    property bool active: false
    property bool hasDetail: false
    signal toggled
    signal detail

    width: 112
    height: 58
    radius: 12
    color: active ? (main.containsMouse ? Qt.lighter(Theme.blue, 1.1) : Theme.blue)
                  : (main.containsMouse ? Theme.surface1 : Theme.base)

    Column {
        anchors.left: parent.left
        anchors.leftMargin: 10
        anchors.right: root.hasDetail ? chevron.left : parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 1

        BarText {
            anchors.verticalCenter: undefined
            text: root.icon
            color: root.active ? Theme.base : Theme.text
        }
        ThemedText {
            width: parent.width
            elide: Text.ElideRight
            text: root.label
            font.pixelSize: 12
            font.bold: true
            color: root.active ? Theme.base : Theme.text
        }
        ThemedText {
            width: parent.width
            elide: Text.ElideRight
            text: root.sublabel
            font.pixelSize: 10
            color: root.active ? Theme.base : Theme.subtext
            visible: text !== ""
        }
    }

    MouseArea {
        id: main
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }

    Rectangle {
        id: chevron
        visible: root.hasDetail
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 24
        radius: 12
        color: chevMouse.containsMouse ? Qt.rgba(0, 0, 0, 0.15) : "transparent"

        BarText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: ""   // ›
            font.pixelSize: 10
            color: root.active ? Theme.base : Theme.subtext
        }
        MouseArea {
            id: chevMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.detail()
        }
    }
}
