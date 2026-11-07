// Painel de wallpapers na ilha: grade de miniaturas da pasta ~/Imagens/Wallpapers.
// Clique ou Enter aplica (o painel continua aberto para experimentar), R = aleatório,
// setas escolhem, Esc fecha. O atual tem borda azul.

import QtQuick
import Quickshell
import Quickshell.Widgets
import qs

IslandView {
    id: root

    readonly property int columns: 4
    readonly property int tileW: 230
    readonly property int tileH: 130
    readonly property int gap: 10
    property int current: 0

    padH: 14
    padV: 14

    onShownChanged: {
        if (shown) {
            current = Math.max(0, Wallpaper.images.findIndex(i => i.path === Wallpaper.current));
            keys.forceActiveFocus();
        }
    }

    function select(index) {
        const n = Wallpaper.images.length;
        if (n === 0)
            return;
        current = Math.max(0, Math.min(n - 1, index));
        // Mantém a miniatura escolhida visível na rolagem.
        const row = Math.floor(current / columns);
        const top = row * (tileH + gap);
        if (top < flick.contentY)
            flick.contentY = top;
        else if (top + tileH > flick.contentY + flick.height)
            flick.contentY = top + tileH - flick.height;
    }

    Item {
        id: keys
        focus: true
        width: content.width
        height: content.height

        Keys.onPressed: event => {
            const img = Wallpaper.images[root.current];
            if (event.key === Qt.Key_Escape)
                Wallpaper.close();
            else if (event.key === Qt.Key_Right)
                root.select(root.current + 1);
            else if (event.key === Qt.Key_Left)
                root.select(root.current - 1);
            else if (event.key === Qt.Key_Down)
                root.select(root.current + root.columns);
            else if (event.key === Qt.Key_Up)
                root.select(root.current - root.columns);
            else if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) && img)
                Wallpaper.apply(img.path);
            else if (event.key === Qt.Key_R)
                Wallpaper.random();
            else
                return;
            event.accepted = true;
        }

        Column {
            id: content
            spacing: 10

            // Cabeçalho
            Item {
                width: grid.width
                height: 26

                ThemedText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: `\u{f02e9}  Wallpapers  ·  ${Wallpaper.images.length}`
                    font.pixelSize: 15
                }
                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6

                    SmallButton {
                        text: `\u{f0450}  Trocar sozinho: ${Wallpaper.autoLabel()}`
                        onClicked: Wallpaper.cycleAuto()
                    }
                    SmallButton {
                        text: "  Aleatório (R)"
                        onClicked: Wallpaper.random()
                    }
                    SmallButton {
                        text: "  Abrir pasta"
                        onClicked: {
                            Quickshell.execDetached(["xdg-open", Wallpaper.folder]);
                            Wallpaper.close();
                        }
                    }
                }
            }

            Flickable {
                id: flick
                width: grid.width
                height: Math.min(grid.height, 3 * (root.tileH + root.gap) + root.tileH / 2)
                contentHeight: grid.height
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Behavior on contentY {
                    NumberAnimation { duration: 120 }
                }

                Grid {
                    id: grid
                    columns: root.columns
                    spacing: root.gap

                    Repeater {
                        model: Wallpaper.images

                        ClippingRectangle {
                            id: tile

                            required property var modelData
                            required property int index
                            readonly property bool isCurrent: modelData.path === Wallpaper.current
                            readonly property bool selected: root.current === index

                            width: root.tileW
                            height: root.tileH
                            radius: 12
                            color: Theme.base

                            Image {
                                anchors.fill: parent
                                source: "file://" + tile.modelData.thumb
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                cache: false
                            }

                            // Borda: azul = atual; clara = selecionado
                            Rectangle {
                                anchors.fill: parent
                                radius: tile.radius
                                color: "transparent"
                                border.width: tile.isCurrent ? 3 : tile.selected ? 2 : 0
                                border.color: tile.isCurrent ? Theme.blue : Theme.text
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: root.current = tile.index
                                onClicked: Wallpaper.apply(tile.modelData.path)
                            }
                        }
                    }
                }
            }

            ThemedText {
                width: grid.width
                elide: Text.ElideMiddle
                text: {
                    const img = Wallpaper.images[root.current];
                    return img ? img.path.split("/").pop() : "Carregando miniaturas…";
                }
                color: Theme.overlay
                font.pixelSize: 11
                font.weight: Font.Normal
            }
        }
    }
}
