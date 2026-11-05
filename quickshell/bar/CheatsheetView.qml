// Guia de atalhos na ilha: os atalhos do Hyprland agrupados por categoria, em colunas.
// Fecha com Esc, SUPER + / de novo ou clicando fora.

import QtQuick
import qs

IslandView {
    id: root

    padH: 16
    padV: 14

    readonly property int columnWidth: 340

    // Distribui as categorias em 3 colunas: cada uma vai para a coluna mais baixa.
    readonly property var columns: {
        const cols = [[], [], []];
        const heights = [0, 0, 0];
        for (const g of Cheatsheet.groups) {
            const i = heights.indexOf(Math.min(...heights));
            cols[i].push(g);
            heights[i] += g.items.length + 2; // +2: título e espaço da categoria
        }
        return cols;
    }

    onShownChanged: if (shown) keys.forceActiveFocus()

    Item {
        id: keys
        focus: true
        width: content.width
        height: content.height
        Keys.onEscapePressed: Cheatsheet.close()

        Column {
            id: content
            spacing: 10

            ThemedText {
                text: "  Atalhos"
                font.pixelSize: 15
            }

            // Categorias distribuídas em 3 colunas de alturas parecidas.
            Row {
                spacing: 24

                Repeater {
                    model: root.columns

                    Column {
                        required property var modelData
                        width: root.columnWidth
                        spacing: 12

                        Repeater {
                            model: parent.modelData

                            Column {
                                required property var modelData
                                width: root.columnWidth
                                spacing: 4

                                ThemedText {
                                    text: parent.modelData.category
                                    color: Theme.blue
                                    font.pixelSize: 13
                                    bottomPadding: 2
                                }

                                Repeater {
                                    model: parent.modelData.items

                                    Row {
                                        required property var modelData
                                        spacing: 10

                                        Rectangle {
                                            width: 140
                                            height: 20
                                            radius: 5
                                            color: Theme.base

                                            ThemedText {
                                                anchors.centerIn: parent
                                                width: parent.width - 10
                                                horizontalAlignment: Text.AlignHCenter
                                                elide: Text.ElideRight
                                                text: parent.parent.modelData.keys
                                                font.pixelSize: 11
                                            }
                                        }
                                        ThemedText {
                                            width: root.columnWidth - 150
                                            anchors.verticalCenter: parent.verticalCenter
                                            elide: Text.ElideRight
                                            text: parent.modelData.text
                                            color: Theme.subtext
                                            font.pixelSize: 12
                                            font.weight: Font.Normal
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            ThemedText {
                text: "Os atalhos vêm do hyprland.lua (opção description = \"Categoria · O que faz\")  ·  Esc fecha"
                color: Theme.overlay
                font.pixelSize: 11
                font.weight: Font.Normal
            }
        }
    }
}
