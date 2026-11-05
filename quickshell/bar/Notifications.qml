// Botão de notificações: sino + quantidade.
// Clique esquerdo: abre/fecha o painel. Clique direito: liga/desliga o "não perturbe".

import QtQuick
import qs

Pill {
    id: root

    readonly property int count: NotificationService.history.length

    clickable: true
    color: hovered ? Theme.surface1 : Theme.base

    BarText {
        text: (NotificationService.dnd ? "\u{f009b}" : "\u{f009a}") + (root.count > 0 ? " " + root.count : "")
    }

    onClicked: mouse => {
        if (mouse.button === Qt.RightButton)
            NotificationService.dnd = !NotificationService.dnd;
        else
            NotificationService.centerOpen = !NotificationService.centerOpen;
        if (NotificationService.centerOpen) {
            QuickSettings.close();
            PowerMenu.close();
            Cheatsheet.close();
            Wallpaper.close();
        }
    }
}
