// Ilha aberta (mouse em cima):
//   esquerda: workspaces, mídia (se houver), bateria / perfil de energia / wi-fi / bluetooth
//             e controles (bandeja, volume, sino, power); atualizações pendentes
//   direita:  hora, data por extenso e calendário do mês

import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import qs

IslandView {
    id: root

    required property var window
    property MprisPlayer player

    padH: 14
    padV: 14

    // Ao fechar a ilha, o calendário volta para o mês atual.
    onShownChanged: if (!shown) calendar.offset = 0

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    Row {
        spacing: 18

        // Esquerda
        Column {
            spacing: 10

            Workspaces {}

            Rectangle {
                visible: root.player !== null
                width: media.width + 20
                height: Theme.barHeight
                radius: Theme.radius
                color: Theme.base

                MediaRow {
                    id: media
                    anchors.centerIn: parent
                    player: root.player
                    maxTextWidth: 200
                }
            }

            Row {
                spacing: Theme.gap

                BatteryPill {}
                PowerProfilePill {}
                WifiPill {}
                BluetoothPill {}
                RecordPill { stoppable: true }
            }

            // Atualizações pendentes (só aparece quando há alguma)
            UpdatesPill {}

            Row {
                spacing: Theme.gap

                Tray { bar: root.window }
                Volume {}
                Notifications {}
                WallpaperButton {}
                PowerButton {}
            }
        }

        // Direita
        Column {
            spacing: 4

            BarText {
                anchors.verticalCenter: undefined
                text: Qt.formatDateTime(clock.date, "HH:mm:ss")
                font.pixelSize: 26
            }
            BarText {
                anchors.verticalCenter: undefined
                text: Qt.locale().toString(clock.date, "dddd, d 'de' MMMM")
                color: Theme.subtext
                font.pixelSize: 12
            }
            Item { width: 1; height: 4 }
            Calendar {
                id: calendar
                date: clock.date
            }
        }
    }
}
