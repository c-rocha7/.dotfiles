// Uma linha do launcher: ícone, nome e descrição.

import QtQuick
import Quickshell
import Quickshell.Widgets
import qs

Item {
    id: root

    property var item // { name, desc, icon ou glyph }
    property bool selected: false

    signal hovered
    signal clicked

    // Ícone: do tema (apps/janelas), miniatura (imagem do clipboard), emoji
    // ou ícone da fonte (calculadora, comandos, texto do clipboard).
    readonly property string kind: item?.image ? "image" : item?.emoji ? "emoji" : item?.icon ? "icon" : "glyph"

    Item {
        id: iconBox
        x: 10
        width: 26
        height: 26
        anchors.verticalCenter: parent.verticalCenter

        IconImage {
            anchors.fill: parent
            visible: root.kind === "icon"
            source: root.kind === "icon" ? Quickshell.iconPath(root.item.icon, "application-x-executable") : ""
        }
        ClipImage {
            anchors.fill: parent
            visible: root.kind === "image"
            clipId: root.kind === "image" ? root.item.id : ""
            clipText: root.item?.desc ?? ""
            previewWidth: 64
        }
        Text {
            anchors.centerIn: parent
            visible: root.kind === "emoji"
            text: root.item?.emoji ?? ""
            font.family: "Noto Color Emoji"
            font.pixelSize: 20
        }
        ThemedText {
            anchors.centerIn: parent
            visible: root.kind === "glyph"
            text: root.item?.glyph ?? ""
            color: root.selected ? Theme.blue : Theme.subtext
            font.pixelSize: 16
        }
    }

    Row {
        anchors.left: iconBox.right
        anchors.leftMargin: 12
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        ThemedText {
            id: name
            width: Math.min(implicitWidth, root.item?.desc ? parent.width * 0.6 : parent.width)
            elide: Text.ElideRight
            text: root.item?.name ?? ""
            color: root.selected ? Theme.text : Theme.subtext
        }
        ThemedText {
            width: parent.width - name.width - parent.spacing
            elide: Text.ElideRight
            anchors.baseline: name.baseline
            text: root.item?.desc ?? ""
            color: Theme.overlay
            font.pixelSize: 12
            font.weight: Font.Normal
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: root.hovered()
        onClicked: root.clicked()
    }
}
