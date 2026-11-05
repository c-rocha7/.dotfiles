// Ilha fechada: workspace atual · hora.
// Sino cortado: "não perturbe" ligado. Pontinho azul: há notificações no painel.
// Bateria em vermelho: abaixo de 20% fora da tomada. Ícone azul de teclado: Caps Lock ligado.
// Ponto vermelho + tempo: gravando a tela. Controle verde: GameMode ativo (jogo aberto).

import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs

IslandView {
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Row {
        spacing: 10

        BarText {
            text: Hyprland.focusedWorkspace?.id ?? "-"
            color: Theme.blue
        }
        BarText {
            text: "·"
            color: Theme.overlay
        }
        BarText {
            text: Qt.formatDateTime(clock.date, "HH:mm")
        }
        BarText {
            visible: NotificationService.dnd
            text: "\u{f009b}"
            color: Theme.subtext
        }

        // Gravando a tela: ponto vermelho + tempo
        RecordPill {
            color: "transparent"
            padding: 0
            anchors.verticalCenter: parent.verticalCenter
        }

        // GameMode ativo (jogo aberto)
        BarText {
            visible: GameMode.active
            text: "\u{f0297}"
            color: Theme.green
        }

        // Caps Lock ligado
        BarText {
            visible: Keyboard.capsLock
            text: "\u{f0632}"
            color: Theme.blue
        }

        // Bateria fraca (abaixo de 20% fora da tomada)
        BarText {
            visible: Battery.low
            text: `${Battery.icon} ${Battery.percent}%`
            color: Theme.red
        }

        // Pontinho azul: há notificações no painel
        Rectangle {
            visible: !NotificationService.dnd && NotificationService.history.length > 0
            width: 6
            height: 6
            radius: 3
            color: Theme.blue
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
