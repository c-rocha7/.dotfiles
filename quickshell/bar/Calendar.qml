// Calendário com navegação entre os meses.
// - rolar o mouse em cima: para cima = mês anterior, para baixo = próximo
// - setas ‹ › no cabeçalho também trocam o mês
// - clicar no nome do mês volta para o mês atual
// O dia de hoje fica destacado em azul (só no mês atual).

import QtQuick
import QtQuick.Controls
import qs

Column {
    id: root

    property date date: new Date()   // hoje (vem do relógio da ilha)
    property int offset: 0           // quantos meses para frente/trás do atual
    property int cell: 26            // largura de cada dia (o painel da moldura usa maior)
    property int rowHeight: 22
    property int dayFont: 11

    // Primeiro dia do mês mostrado (o Date ajusta a virada de ano sozinho).
    readonly property date shown: new Date(date.getFullYear(), date.getMonth() + offset, 1)

    spacing: 4

    // Rolagem troca o mês (precisa ficar na coluna inteira, não só na grade).
    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => {
            if (event.angleDelta.y > 0)
                root.offset -= 1;
            else if (event.angleDelta.y < 0)
                root.offset += 1;
        }
    }

    // Cabeçalho: ‹  novembro de 2026  ›
    Item {
        width: root.cell * 7
        height: 22

        CalendarNavButton {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: ""
            onClicked: root.offset -= 1
        }

        ThemedText {
            anchors.centerIn: parent
            text: {
                const name = Qt.locale().toString(root.shown, "MMMM 'de' yyyy");
                return name.charAt(0).toUpperCase() + name.slice(1);
            }
            color: root.offset === 0 ? Theme.text : Theme.blue
            font.pixelSize: 12

            MouseArea {
                anchors.fill: parent
                anchors.margins: -4
                enabled: root.offset !== 0
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: root.offset = 0 // volta para hoje
            }
        }

        CalendarNavButton {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: ""
            onClicked: root.offset += 1
        }
    }

    // Iniciais dos dias da semana (D S T Q Q S S)
    DayOfWeekRow {
        width: root.cell * 7
        locale: Qt.locale()
        spacing: 0
        delegate: Text {
            required property string narrowName
            text: narrowName.toUpperCase()
            horizontalAlignment: Text.AlignHCenter
            color: Theme.overlay
            font.family: Theme.font
            font.pixelSize: 11
            font.weight: Font.DemiBold
        }
    }

    MonthGrid {
        id: grid
        width: root.cell * 7
        month: root.shown.getMonth()
        year: root.shown.getFullYear()
        locale: Qt.locale()
        spacing: 0

        delegate: Rectangle {
            required property int day
            required property int month
            required property bool today

            implicitWidth: root.cell
            implicitHeight: root.rowHeight
            radius: 6
            color: today ? Theme.blue : "transparent"

            Text {
                anchors.centerIn: parent
                text: parent.day
                color: parent.today ? Theme.base
                    : parent.month === grid.month ? Theme.text
                    : Theme.overlay
                font.family: Theme.font
                font.pixelSize: root.dayFont
                font.weight: Font.DemiBold
            }
        }
    }

}
