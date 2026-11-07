// Página "Sistema" da central de controle: alertas, disco, memória, temperaturas, snapshots,
// atualizações e travamentos desde o boot.

import QtQuick
import Quickshell
import qs
import qs.bar

Column {
    id: root

    readonly property var d: Health.data
    width: 352
    spacing: 8

    function tempColor(t, warn, bad) {
        const n = Number(t);
        return n >= bad ? Theme.red : n >= warn ? Theme.yellow : Theme.text;
    }

    // Alertas (ou "tudo certo")
    Rectangle {
        width: parent.width
        height: alertCol.implicitHeight + 16
        radius: 10
        color: Theme.base
        Column {
            id: alertCol
            x: 10
            y: 8
            width: parent.width - 20
            spacing: 4
            Repeater {
                model: Health.alerts
                ThemedText {
                    required property string modelData
                    width: alertCol.width
                    wrapMode: Text.WordWrap
                    text: "\u{f0026}  " + modelData
                    color: Theme.red
                    font.pixelSize: 12
                }
            }
            ThemedText {
                visible: Health.loaded && Health.alerts.length === 0
                text: "\u{f05e0}  Tudo certo"
                color: Theme.green
                font.bold: true
            }
        }
    }

    // Barras: disco e memória
    Repeater {
        model: root.d ? [
            { icon: "\u{f02ca}", label: "Disco", pct: Health.diskPct, info: `${Health.gb(root.d.disco.livre)} GB livres de ${Health.gb(root.d.disco.total)}` },
            { icon: "\u{f035b}", label: "Memória", pct: Health.memPct, info: `${Health.gb(root.d.memoria.total - root.d.memoria.livre)} de ${Health.gb(root.d.memoria.total)} GB` }
        ] : []

        Rectangle {
            required property var modelData
            width: root.width
            height: 48
            radius: 10
            color: Theme.base
            Row {
                x: 10
                y: 7
                spacing: 8
                BarText { text: modelData.icon }
                ThemedText { anchors.verticalCenter: parent.verticalCenter; text: modelData.label; font.bold: true }
                ThemedText { anchors.verticalCenter: parent.verticalCenter; text: modelData.info; font.pixelSize: 11; color: Theme.subtext }
            }
            Rectangle {
                x: 10
                y: 32
                width: parent.width - 20
                height: 6
                radius: 3
                color: Theme.surface1
                Rectangle {
                    width: parent.width * modelData.pct / 100
                    height: parent.height
                    radius: 3
                    color: modelData.pct >= 90 ? Theme.red : modelData.pct >= 75 ? Theme.yellow : Theme.blue
                }
            }
        }
    }

    // Temperaturas
    Rectangle {
        visible: !!root.d
        width: parent.width
        height: 34
        radius: 10
        color: Theme.base
        Row {
            anchors.centerIn: parent
            spacing: 22
            Repeater {
                model: root.d ? [
                    { label: "CPU", t: root.d.temp.cpu, warn: 80, bad: 90 },
                    { label: "GPU", t: root.d.temp.gpu, warn: 80, bad: 90 },
                    { label: "SSD", t: root.d.temp.ssd, warn: 60, bad: 70 }
                ].filter(x => x.t !== "") : []
                Row {
                    required property var modelData
                    spacing: 5
                    ThemedText { text: modelData.label; font.pixelSize: 12; color: Theme.subtext }
                    ThemedText { text: `${modelData.t} °C`; font.pixelSize: 12; font.bold: true; color: root.tempColor(modelData.t, modelData.warn, modelData.bad) }
                }
            }
        }
    }

    // Snapshots, atualizações, tempo ligado
    Rectangle {
        visible: !!root.d
        width: parent.width
        height: infoCol.implicitHeight + 16
        radius: 10
        color: Theme.base
        Column {
            id: infoCol
            x: 10
            y: 8
            spacing: 4
            Repeater {
                model: root.d ? [
                    ["\u{f02da}", "Snapshot do sistema", (root.d.snapshots.root.split("|")[1] ?? "—").slice(0, 16)],
                    ["\u{f02da}", "Snapshot do /home", (root.d.snapshots.home.split("|")[1] ?? "—").slice(0, 16)],
                    ["\u{f06b0}", "Atualizações", Updates.count ? `${Updates.count} pendentes` : "em dia"],
                    ["\u{f0954}", "Ligado há", root.d.ligado]
                ] : []
                Row {
                    required property var modelData
                    spacing: 8
                    BarText { text: modelData[0]; font.pixelSize: 12; color: Theme.subtext }
                    ThemedText { text: modelData[1]; font.pixelSize: 12; color: Theme.subtext; width: 150 }
                    ThemedText { text: modelData[2]; font.pixelSize: 12 }
                }
            }
        }
    }

    // Travamentos desde o boot
    Rectangle {
        visible: !!root.d && root.d.travamentos.length > 0
        width: parent.width
        height: crashCol.implicitHeight + 16
        radius: 10
        color: Theme.base
        Column {
            id: crashCol
            x: 10
            y: 8
            width: parent.width - 20
            spacing: 3
            ThemedText {
                text: `\u{f00e4}  Travamentos desde o boot (${root.d?.travamentos.length ?? 0})`
                font.pixelSize: 12
                font.bold: true
                color: Theme.yellow
            }
            ThemedText {
                width: parent.width
                wrapMode: Text.WordWrap
                font.pixelSize: 11
                color: Theme.subtext
                text: (root.d?.travamentos ?? []).slice(0, 6).map(t => `${t.hora} ${t.programa}`).join("  ·  ")
            }
        }
    }

    Row {
        spacing: 6
        SmallButton {
            text: "\u{f0450}  Atualizar"
            onClicked: Health.refresh()
        }
        SmallButton {
            text: "\u{f02da}  Snapshots"
            onClicked: Quickshell.execDetached(["btrfs-assistant"])
        }
    }
}
