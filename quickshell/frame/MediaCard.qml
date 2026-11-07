// Cartão de mídia (painel do calendário): capa, título/artista, progresso arrastável,
// anterior / tocar-pausar / próximo. Com mais de um player, ⇄ troca entre eles.

import QtQuick
import Quickshell.Services.Mpris
import qs
import qs.bar

Rectangle {
    id: root

    property int index: -1                     // -1 = o que estiver tocando
    readonly property var players: Mpris.players.values
    readonly property MprisPlayer player: index >= 0 && index < players.length ? players[index]
        : (players.find(p => p.isPlaying) ?? players[0] ?? null)

    visible: player !== null
    width: 320
    height: 128
    radius: 12
    color: Theme.base

    // A posição do MPRIS não se atualiza sozinha: pede a cada segundo enquanto toca.
    Timer {
        running: root.visible && (root.player?.isPlaying ?? false)
        interval: 1000
        repeat: true
        onTriggered: root.player.positionChanged()
    }

    function fmt(s) {
        if (!s || s < 0) return "0:00";
        const h = Math.floor(s / 3600), m = Math.floor((s % 3600) / 60), r = Math.floor(s % 60);
        const mm = h > 0 ? String(m).padStart(2, "0") : String(m);
        return (h > 0 ? `${h}:` : "") + `${mm}:${String(r).padStart(2, "0")}`;
    }

    Rectangle {
        id: art
        x: 10
        y: 10
        width: 88
        height: 88
        radius: 10
        color: Theme.surface1
        clip: true
        Image {
            anchors.fill: parent
            source: root.player?.trackArtUrl ?? ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            visible: status === Image.Ready
        }
        BarText {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: !(root.player?.trackArtUrl)
            text: ""
            color: Theme.overlay
        }
    }

    Column {
        anchors.left: art.right
        anchors.leftMargin: 10
        anchors.right: parent.right
        anchors.rightMargin: 10
        y: 10
        spacing: 2

        Row {
            width: parent.width
            ThemedText {
                width: parent.width - (switcher.visible ? switcher.width : 0)
                elide: Text.ElideRight
                font.bold: true
                font.pixelSize: 15
                text: root.player?.trackTitle || root.player?.identity || ""
            }
            ThemedText {
                id: switcher
                visible: root.players.length > 1
                text: "\u{f04e6}"   // ⇄
                color: swMouse.containsMouse ? Theme.blue : Theme.subtext
                MouseArea {
                    id: swMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        const cur = root.players.indexOf(root.player);
                        root.index = (cur + 1) % root.players.length;
                    }
                }
            }
        }
        ThemedText {
            width: parent.width
            elide: Text.ElideRight
            font.pixelSize: 13
            color: Theme.subtext
            text: root.player?.trackArtist || root.player?.identity || ""
        }

        // Botões
        Row {
            spacing: 14
            topPadding: 6
            Repeater {
                model: [
                    { icon: "", act: "prev", enabled: root.player?.canGoPrevious ?? false },
                    { icon: (root.player?.isPlaying ?? false) ? "" : "", act: "toggle", enabled: root.player?.canTogglePlaying ?? false },
                    { icon: "", act: "next", enabled: root.player?.canGoNext ?? false }
                ]
                // Caixa de tamanho fixo com o ícone centralizado: os três ficam alinhados
                Item {
                    required property var modelData
                    width: 30
                    height: 30
                    BarText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        font.pixelSize: modelData.act === "toggle" ? 22 : 17
                        text: modelData.icon
                        color: !modelData.enabled ? Theme.overlay : btn.containsMouse ? Theme.blue : Theme.text
                    }
                    MouseArea {
                        id: btn
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (!modelData.enabled) return;
                            if (modelData.act === "prev") root.player.previous();
                            else if (modelData.act === "next") root.player.next();
                            else root.player.togglePlaying();
                        }
                    }
                }
            }
        }
    }

    // Progresso (clique/arraste: pula, se o player deixar)
    Item {
        x: 10
        y: 104
        width: parent.width - 20
        height: 20
        readonly property real len: root.player?.length ?? 0
        readonly property real frac: len > 0 ? Math.min(1, (root.player?.position ?? 0) / len) : 0

        ThemedText {
            id: posText
            anchors.verticalCenter: parent.verticalCenter
            font.pixelSize: 10
            color: Theme.subtext
            text: root.fmt(root.player?.position ?? 0)
        }
        Rectangle {
            id: track
            anchors.left: posText.right
            anchors.leftMargin: 8
            anchors.right: lenText.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            height: 4
            radius: 2
            color: Theme.surface1
            Rectangle {
                width: parent.width * parent.parent.frac
                height: parent.height
                radius: 2
                color: Theme.green
            }
            MouseArea {
                anchors.fill: parent
                anchors.margins: -6
                enabled: root.player?.canSeek ?? false
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                function seekTo(x) { root.player.position = Math.max(0, Math.min(1, x / track.width)) * parent.parent.len; }
                onPressed: m => seekTo(m.x - 6)
                onPositionChanged: m => { if (pressed) seekTo(m.x - 6); }
            }
        }
        ThemedText {
            id: lenText
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            font.pixelSize: 10
            color: Theme.subtext
            text: root.fmt(parent.len)
        }
    }
}
