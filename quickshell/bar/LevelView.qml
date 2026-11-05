// Aviso com barra de nível (usado pelo volume e pelo brilho):
// ícone, barra de progresso e texto.

import QtQuick
import qs

IslandView {
    id: root

    property string icon
    property real value: 0  // de 0 a 1
    property string label   // ex.: "45%"
    property bool dim: false // barra apagada (ex.: mudo)

    Row {
        spacing: 12
        height: Theme.barHeight

        BarText {
            width: 18
            text: root.icon
        }

        // Trilho + preenchimento
        Rectangle {
            width: 180
            height: 6
            radius: 3
            color: Theme.surface1
            anchors.verticalCenter: parent.verticalCenter

            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, root.value))
                height: parent.height
                radius: 3
                color: root.dim ? Theme.overlay : Theme.blue

                Behavior on width {
                    NumberAnimation { duration: 120 }
                }
            }
        }

        BarText {
            width: 40
            horizontalAlignment: Text.AlignRight
            text: root.label
        }
    }
}
