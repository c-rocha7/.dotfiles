// Seletor de áudio antes de gravar a tela: Sem áudio / Som do PC / PC + microfone.
// Começa marcado na última escolha (Enter já grava com ela).
// Teclas: 1/2/3, ←/→ e Enter, Esc cancela. Depois, "região" pede a seleção com o mouse.

import QtQuick
import qs

IslandView {
    id: root

    property int current: 1

    padH: 14
    padV: 14

    onShownChanged: {
        if (shown) {
            current = Math.max(0, Recorder.audioOptions.findIndex(o => o.id === Recorder.audio));
            keys.forceActiveFocus();
        }
    }

    function choose(index) {
        Recorder.start(Recorder.audioOptions[index].id);
    }

    Item {
        id: keys
        focus: true
        width: content.width
        height: content.height

        Keys.onPressed: event => {
            const n = Recorder.audioOptions.length;
            if (event.key === Qt.Key_Escape)
                Recorder.pickerOpen = false;
            else if (event.key === Qt.Key_Right || event.key === Qt.Key_Tab)
                root.current = (root.current + 1) % n;
            else if (event.key === Qt.Key_Left || event.key === Qt.Key_Backtab)
                root.current = (root.current - 1 + n) % n;
            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space)
                root.choose(root.current);
            else if (event.key >= Qt.Key_1 && event.key < Qt.Key_1 + n)
                root.choose(event.key - Qt.Key_1);
            else
                return;
            event.accepted = true;
        }

        Column {
            id: content
            spacing: 10

            ThemedText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Recorder.mode === "region" ? "\u{f044a}  Gravar uma região" : "\u{f044a}  Gravar a tela inteira"
                color: Theme.red
                font.pixelSize: 14
            }

            Row {
                spacing: 8

                Repeater {
                    model: Recorder.audioOptions

                    Rectangle {
                        id: tile

                        required property var modelData
                        required property int index
                        readonly property bool selected: root.current === index

                        width: 140
                        height: 84
                        radius: 16
                        color: selected ? Theme.surface1 : Theme.base
                        border.width: selected ? 2 : 0
                        border.color: Theme.red

                        Column {
                            anchors.centerIn: parent
                            spacing: 8

                            ThemedText {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: tile.modelData.glyph
                                font.pixelSize: 24
                            }
                            ThemedText {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: `${tile.index + 1}  ${tile.modelData.name}`
                                color: Theme.subtext
                                font.pixelSize: 12
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: root.current = tile.index
                            onClicked: root.choose(tile.index)
                        }
                    }
                }
            }

            ThemedText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Recorder.mode === "region" ? "Escolha o áudio · depois selecione a região · Esc cancela"
                                                 : "Escolha o áudio · Esc cancela"
                color: Theme.overlay
                font.pixelSize: 11
                font.weight: Font.Normal
            }
        }
    }
}
