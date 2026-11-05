// Aviso de notificação na ilha: ícone, título e o começo do texto.
// Clique esquerdo: ação padrão do app (ex.: abrir a conversa). Clique direito: dispensa.

import QtQuick
import Quickshell.Services.Notifications
import qs

IslandView {
    id: root

    property Notification notification

    // Pedido para a ilha esconder o aviso.
    signal hide

    padH: 14
    padV: 8

    Row {
        spacing: 12

        NotifIcon {
            notification: root.notification
            size: 30
            anchors.verticalCenter: parent.verticalCenter
        }

        Column {
            spacing: 2
            anchors.verticalCenter: parent.verticalCenter

            ThemedText {
                width: Math.min(implicitWidth, 380)
                elide: Text.ElideRight
                text: root.notification?.summary || root.notification?.appName || ""
            }
            ThemedText {
                visible: text !== ""
                width: Math.min(implicitWidth, 380)
                elide: Text.ElideRight
                text: (root.notification?.body ?? "").replace(/\s+/g, " ")
                color: Theme.subtext
                font.pixelSize: 12
                font.weight: Font.Normal
            }
        }
    }

    MouseArea {
        parent: root
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => {
            const n = root.notification;
            if (n && (mouse.button === Qt.RightButton || !NotificationService.invokeDefault(n)))
                n.dismiss();
            root.hide();
        }
    }
}
