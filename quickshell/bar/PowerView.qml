// Menu de energia na ilha: Bloquear, Suspender, Sair, Reiniciar, Desligar.
// Sair/Reiniciar/Desligar pedem confirmação (segundo clique ou Enter).
// Teclas: ←/→ ou Tab escolhem, Enter executa, Esc fecha.
// Atalhos: B bloquear, S suspender, E sair, R reiniciar, D desligar.

import QtQuick
import qs

IslandView {
    id: root

    property int current: 0
    property string confirming: "" // id da ação aguardando confirmação

    readonly property var letters: ({ lock: Qt.Key_B, suspend: Qt.Key_S, logout: Qt.Key_E, reboot: Qt.Key_R, poweroff: Qt.Key_D })

    padH: 14
    padV: 14

    onShownChanged: {
        if (shown) {
            current = 0;
            confirming = "";
            keys.forceActiveFocus();
        }
    }

    // Executa ou pede confirmação.
    function trigger(index) {
        const action = PowerMenu.actions[index];
        current = index;
        if (action.confirm && confirming !== action.id) {
            confirming = action.id;
            return;
        }
        PowerMenu.run(action);
    }

    Item {
        id: keys
        focus: true
        width: content.width
        height: content.height

        Keys.onPressed: event => {
            const n = PowerMenu.actions.length;
            if (event.key === Qt.Key_Escape) {
                PowerMenu.close();
            } else if (event.key === Qt.Key_Right || event.key === Qt.Key_Tab) {
                root.current = (root.current + 1) % n;
                root.confirming = "";
            } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Backtab) {
                root.current = (root.current - 1 + n) % n;
                root.confirming = "";
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                root.trigger(root.current);
            } else {
                const index = PowerMenu.actions.findIndex(a => root.letters[a.id] === event.key);
                if (index < 0)
                    return;
                root.trigger(index);
            }
            event.accepted = true;
        }

        Column {
            id: content
            spacing: 10

            Row {
                spacing: 8

                Repeater {
                    model: PowerMenu.actions

                    Rectangle {
                        id: tile

                        required property var modelData
                        required property int index
                        readonly property bool selected: root.current === index
                        readonly property bool asking: root.confirming === modelData.id

                        width: 92
                        height: 92
                        radius: 16
                        color: asking ? Theme.red : selected ? Theme.surface1 : Theme.base
                        border.width: selected && !asking ? 2 : 0
                        border.color: Theme.blue

                        Behavior on color {
                            ColorAnimation { duration: 120 }
                        }

                        Column {
                            anchors.centerIn: parent
                            spacing: 8

                            ThemedText {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: tile.modelData.glyph
                                color: tile.asking ? Theme.base : tile.modelData.id === "poweroff" ? Theme.red : Theme.text
                                font.pixelSize: 28
                            }
                            ThemedText {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: tile.asking ? "Confirmar?" : tile.modelData.name
                                color: tile.asking ? Theme.base : Theme.subtext
                                font.pixelSize: 12
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: {
                                if (root.current !== tile.index)
                                    root.confirming = "";
                                root.current = tile.index;
                            }
                            onClicked: root.trigger(tile.index)
                        }
                    }
                }
            }

            ThemedText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.confirming !== "" ? "Clique de novo ou Enter para confirmar · Esc cancela"
                                             : "B · S · E · R · D   ou   ←/→ e Enter   ·   Esc fecha"
                color: root.confirming !== "" ? Theme.red : Theme.overlay
                font.pixelSize: 11
                font.weight: Font.Normal
            }
        }
    }
}
