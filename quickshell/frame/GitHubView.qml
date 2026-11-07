// Página "GitHub" da central de controle: revisões pedidas, suas PRs e notificações.
// Clique abre no navegador.

import QtQuick
import Quickshell
import qs
import qs.bar

Column {
    id: root

    readonly property var d: GitHub.data
    width: 352
    spacing: 8

    // Sem gh / sem login
    Rectangle {
        visible: !!root.d && !GitHub.ok
        width: parent.width
        height: 50
        radius: 10
        color: Theme.base
        ThemedText {
            anchors.fill: parent
            anchors.margins: 10
            wrapMode: Text.WordWrap
            verticalAlignment: Text.AlignVCenter
            text: root.d?.erro ?? ""
            color: Theme.yellow
            font.pixelSize: 12
        }
    }

    Repeater {
        model: GitHub.ok ? [
            { titulo: "Esperando a sua revisão", icone: "\u{f0a92}", itens: root.d.revisar.map(p => ({ t: p.titulo, s: `${p.repo} #${p.numero}`, url: p.url })) },
            { titulo: "Suas PRs abertas", icone: "\u{f0408}", itens: root.d.minhas.map(p => ({ t: (p.rascunho ? "[rascunho] " : "") + p.titulo, s: `${p.repo} #${p.numero}`, url: p.url })) },
            { titulo: "Notificações", icone: "\u{f009a}", itens: root.d.notificacoes.map(n => ({ t: n.titulo, s: `${n.repo} · ${n.tipo}`, url: n.url })) }
        ] : []

        Column {
            id: section
            required property var modelData
            width: root.width
            spacing: 4

            ThemedText {
                text: `${section.modelData.icone}  ${section.modelData.titulo}  ·  ${section.modelData.itens.length}`
                font.pixelSize: 12
                font.bold: true
                color: Theme.subtext
            }
            ThemedText {
                visible: section.modelData.itens.length === 0
                leftPadding: 22
                text: "nada por aqui"
                font.pixelSize: 11
                color: Theme.overlay
            }
            Repeater {
                model: section.modelData.itens.slice(0, 6)
                Rectangle {
                    required property var modelData
                    width: section.width
                    height: 42
                    radius: 8
                    color: rowMouse.containsMouse ? Theme.surface1 : Theme.base
                    Column {
                        x: 10
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 20
                        ThemedText { width: parent.width; elide: Text.ElideRight; text: modelData.t; font.pixelSize: 12 }
                        ThemedText { width: parent.width; elide: Text.ElideRight; text: modelData.s; font.pixelSize: 10; color: Theme.subtext }
                    }
                    MouseArea {
                        id: rowMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: GitHub.open(modelData.url)
                    }
                }
            }
        }
    }

    Row {
        spacing: 6
        SmallButton {
            text: "\u{f0450}  Atualizar"
            onClicked: GitHub.refresh()
        }
        SmallButton {
            visible: GitHub.ok
            text: "\u{f02a4}  Abrir no GitHub"
            onClicked: GitHub.open("https://github.com/notifications")
        }
    }
}
