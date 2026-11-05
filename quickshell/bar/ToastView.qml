// Aviso curto na ilha: ícone + texto (ex.: "Microfone mudo", "Caps Lock ligado").
// O conteúdo é definido pela Island em showToast().

import QtQuick
import qs

IslandView {
    id: root

    property string icon
    property string text
    property color accent: Theme.text

    padH: 18

    Row {
        spacing: 10
        height: Theme.barHeight

        BarText {
            text: root.icon
            color: root.accent
        }
        BarText {
            text: root.text
        }
    }
}
