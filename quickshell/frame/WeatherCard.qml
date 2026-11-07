// Clima no painel do calendário: agora (ícone, temperatura, descrição, cidade) e 3 dias.

import QtQuick
import qs
import qs.bar

Rectangle {
    id: root

    visible: Weather.ready
    width: 320
    height: 112
    radius: 12
    color: Theme.base

    // Agora
    Row {
        x: 12
        y: 10
        spacing: 10

        ThemedText {
            text: Weather.icon(Weather.code, Weather.isDay)
            font.pixelSize: 30
            color: Theme.blue
        }
        Column {
            ThemedText {
                text: `${Math.round(Weather.temp)}°  ${Weather.description(Weather.code)}`
                font.bold: true
            }
            ThemedText {
                text: Weather.city
                font.pixelSize: 11
                color: Theme.subtext
            }
        }
    }

    // Hoje, amanhã e depois: três colunas iguais (não vaza da borda)
    Row {
        x: 12
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 8
        width: parent.width - 24

        Repeater {
            model: Weather.days
            Column {
                required property var modelData
                required property int index
                width: parent.width / 3
                spacing: 2

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 6
                    ThemedText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: index === 0 ? "Hoje" : Qt.locale().toString(modelData.date, "ddd")
                        font.pixelSize: 11
                        color: Theme.subtext
                    }
                    ThemedText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Weather.icon(modelData.code, true)
                        font.pixelSize: 16
                        color: Theme.blue
                    }
                }
                ThemedText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: `${Math.round(modelData.min)}° / ${Math.round(modelData.max)}°`
                    font.pixelSize: 12
                    font.bold: true
                }
            }
        }
    }
}
