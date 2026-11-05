// Ícone de uma notificação, com cantos arredondados.
// Se o app não mandar ícone (ou ele não existir), mostra um sino.

import QtQuick
import Quickshell.Widgets
import qs

ClippingRectangle {
    id: root

    property var notification
    property int size: 28

    readonly property string source: notification ? NotificationService.iconFor(notification) : ""

    implicitWidth: size
    implicitHeight: size
    radius: 8
    color: Theme.surface1

    Image {
        id: image
        anchors.fill: parent
        source: root.source
        sourceSize.width: root.size * 2
        sourceSize.height: root.size * 2
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        visible: status === Image.Ready
    }

    ThemedText {
        anchors.centerIn: parent
        visible: image.status !== Image.Ready
        text: "\u{f009a}"
        color: Theme.blue
        font.pixelSize: root.size * 0.55
    }
}
