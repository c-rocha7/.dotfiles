// Linha de mídia: capa, título — artista e botões anterior / play-pause / próximo.
// Usada na ilha enquanto algo toca e também na tela de hover.

import QtQuick
import Quickshell.Services.Mpris
import Quickshell.Widgets
import qs

Row {
    id: root

    property MprisPlayer player
    property int maxTextWidth: 260

    spacing: 10
    height: Theme.barHeight

    // Capa do álbum (ou um ícone de nota musical se não houver).
    ClippingRectangle {
        width: 20
        height: 20
        radius: 5
        color: Theme.base
        anchors.verticalCenter: parent.verticalCenter

        Image {
            id: art
            anchors.fill: parent
            source: root.player?.trackArtUrl ?? ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
        }
        BarText {
            visible: art.status !== Image.Ready
            anchors.centerIn: parent
            text: ""
            color: Theme.green
            font.pixelSize: 11
        }
    }

    BarText {
        width: Math.min(implicitWidth, root.maxTextWidth)
        elide: Text.ElideRight
        textFormat: Text.PlainText
        text: {
            const title = root.player?.trackTitle || "Sem título";
            const artist = root.player?.trackArtist ?? "";
            return artist ? `${title} — ${artist}` : title;
        }
    }

    MediaButton {
        icon: ""
        enabled: root.player?.canGoPrevious ?? false
        onClicked: root.player.previous()
    }
    MediaButton {
        icon: root.player?.isPlaying ? "" : ""
        enabled: root.player?.canTogglePlaying ?? false
        onClicked: root.player.togglePlaying()
    }
    MediaButton {
        icon: ""
        enabled: root.player?.canGoNext ?? false
        onClicked: root.player.next()
    }

    component MediaButton: BarText {
        id: button
        property string icon
        signal clicked

        text: icon
        color: !enabled ? Theme.overlay : mouse.containsMouse ? Theme.blue : Theme.text

        MouseArea {
            id: mouse
            anchors.fill: parent
            anchors.margins: -4
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: button.clicked()
        }
    }
}
