// Eventos da agenda de UM dia (painel do calendário): o dia escolhido no calendário (hoje ao abrir).
// Horário numa coluna à esquerda; título (até 2 linhas), local e agenda à direita.
// Sem agenda configurada, mostra como ligar.

import QtQuick
import qs
import qs.bar

Rectangle {
    id: root

    property date now: new Date()
    property date day: new Date()
    readonly property date dayStart: new Date(day.getFullYear(), day.getMonth(), day.getDate())
    readonly property date dayEnd: new Date(day.getFullYear(), day.getMonth(), day.getDate() + 1)
    readonly property bool isToday: dayStart.getTime() === new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime()
    readonly property var items: Agenda.events.filter(e => e.start < dayEnd && e.end > dayStart)
    readonly property bool several: Agenda.ok && new Set(Agenda.events.map(e => e.agenda)).size > 1
    property real maxListHeight: 260

    // Uma cor por agenda (na ordem do arquivo de links)
    function color(i) { return [Theme.blue, Theme.green, Theme.yellow, Theme.red, Theme.subtext][i % 5]; }

    visible: Agenda.data !== null
    height: col.implicitHeight + 20
    radius: 12
    color: Theme.base

    Column {
        id: col
        x: 12
        y: 10
        width: parent.width - 24
        spacing: 8

        // Cabeçalho: "Hoje · sábado, 7 de novembro" + quantidade
        Item {
            width: parent.width
            height: 18
            ThemedText {
                anchors.verticalCenter: parent.verticalCenter
                text: "\u{f00f0}  " + (root.isToday ? "Hoje · " : "") + Qt.locale().toString(root.day, "dddd, d 'de' MMMM")
                font.pixelSize: 12
                font.bold: true
                color: Theme.subtext
            }
            ThemedText {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                visible: Agenda.ok && root.items.length > 0
                text: root.items.length === 1 ? "1 evento" : `${root.items.length} eventos`
                font.pixelSize: 11
                color: Theme.overlay
            }
        }

        ThemedText {
            visible: !Agenda.ok
            width: parent.width
            wrapMode: Text.WordWrap
            text: Agenda.data?.erro ?? ""
            font.pixelSize: 11
            color: Theme.overlay
        }
        ThemedText {
            visible: (Agenda.data?.falharam ?? []).length > 0
            width: parent.width
            wrapMode: Text.WordWrap
            text: `Não consegui baixar: ${(Agenda.data?.falharam ?? []).join(", ")}`
            font.pixelSize: 10
            color: Theme.yellow
        }
        ThemedText {
            visible: Agenda.ok && root.items.length === 0
            text: "Nenhum evento neste dia"
            font.pixelSize: 12
            color: Theme.overlay
            topPadding: 2
            bottomPadding: 2
        }

        Flickable {
            visible: root.items.length > 0
            width: parent.width
            height: Math.min(list.implicitHeight, root.maxListHeight)
            contentHeight: list.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: list
                width: parent.width
                spacing: 10

                Repeater {
                    model: root.items

                    Row {
                        id: ev
                        required property var modelData
                        readonly property bool live: modelData.start <= root.now && modelData.end > root.now
                        width: list.width
                        spacing: 10

                        // Horário
                        Column {
                            width: 44
                            ThemedText {
                                text: ev.modelData.diaInteiro ? "Dia" : Qt.formatTime(ev.modelData.start, "HH:mm")
                                font.pixelSize: 12
                                font.bold: true
                                color: ev.live ? Theme.green : Theme.text
                            }
                            ThemedText {
                                text: ev.modelData.diaInteiro ? "inteiro" : Qt.formatTime(ev.modelData.end, "HH:mm")
                                font.pixelSize: 10
                                color: Theme.overlay
                            }
                        }
                        // Barra da cor da agenda
                        Rectangle {
                            width: 3
                            height: info.implicitHeight
                            radius: 2
                            color: root.color(ev.modelData.cor ?? 0)
                        }
                        // Título, local, agenda
                        Column {
                            id: info
                            width: ev.width - 44 - 3 - 20
                            spacing: 1
                            ThemedText {
                                width: parent.width
                                text: ev.modelData.titulo
                                wrapMode: Text.WordWrap
                                maximumLineCount: 2
                                elide: Text.ElideRight
                                font.pixelSize: 12
                            }
                            ThemedText {
                                width: parent.width
                                visible: text !== ""
                                elide: Text.ElideRight
                                font.pixelSize: 10
                                color: ev.live ? Theme.green : Theme.subtext
                                text: [ev.live ? "agora" : "", ev.modelData.local, root.several ? ev.modelData.agenda : ""]
                                    .filter(x => x).join("  ·  ")
                            }
                        }
                    }
                }
            }
        }
    }
}
