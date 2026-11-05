// Botão de power: abre o menu de energia da ilha.

import QtQuick
import qs

Pill {
    id: root

    clickable: true
    color: hovered ? Theme.red : Theme.base

    BarText {
        text: "" // ícone de power
        color: root.hovered ? Theme.base : Theme.red
    }

    onClicked: PowerMenu.show()
}
