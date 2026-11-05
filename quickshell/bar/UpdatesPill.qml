// Atualizações pendentes (Updates.qml): ícone + total. Só aparece quando há alguma.
// Clique: abre o terminal com "atualizar". Clique direito: confere de novo.

import QtQuick
import qs

Pill {
    id: root

    visible: Updates.count > 0
    clickable: true
    color: hovered ? Theme.surface1 : Theme.base

    BarText {
        text: Updates.checking ? "\u{f0450}" : "\u{f03d7}"   // girando / pacote com seta
        color: Theme.blue
    }
    BarText {
        text: {
            const parts = [];
            if (Updates.repo) parts.push(`${Updates.repo} sistema`);
            if (Updates.aur) parts.push(`${Updates.aur} AUR`);
            if (Updates.flatpak) parts.push(`${Updates.flatpak} flatpak`);
            return parts.join(" · ");
        }
    }

    onClicked: mouse => {
        if (mouse.button === Qt.RightButton)
            Updates.check();
        else
            Updates.run();
    }
}
