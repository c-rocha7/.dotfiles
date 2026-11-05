// Botão da ilha aberta: abre o painel de wallpapers (mesmo que SUPER+W).

import QtQuick
import qs

Pill {
    id: root

    clickable: true
    color: hovered ? Theme.surface1 : Theme.base

    BarText {
        text: "\u{f02e9}"
        color: root.hovered ? Theme.blue : Theme.text
    }

    onClicked: Wallpaper.show()
}
