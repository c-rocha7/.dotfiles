// Painel "Conexões" que sai da ilha: abas Wi-Fi e Bluetooth.
// Abre pelos blocos de Wi-Fi/Bluetooth da ilha; fecha clicando fora ou com Esc.

import QtQuick
import qs

IslandView {
    id: root

    padH: 14
    padV: 14

    Column {
        width: 420
        spacing: 12

        // Abas
        Row {
            spacing: 6

            Tab { tab: "wifi"; label: "\u{f05a9}  Wi-Fi" }
            Tab { tab: "bluetooth"; label: "\u{f00af}  Bluetooth" }
        }

        WifiPanel {
            visible: QuickSettings.tab === "wifi"
            width: parent.width
            active: root.shown && visible
        }

        BluetoothPanel {
            visible: QuickSettings.tab === "bluetooth"
            width: parent.width
            active: root.shown && visible
        }
    }

    component Tab: Rectangle {
        id: tabItem

        property string tab
        property string label
        readonly property bool current: QuickSettings.tab === tabItem.tab

        width: tabText.implicitWidth + 24
        height: 30
        radius: 9
        color: current ? Theme.blue : mouse.containsMouse ? Theme.surface1 : Theme.base

        ThemedText {
            id: tabText
            anchors.centerIn: parent
            text: tabItem.label
            color: tabItem.current ? Theme.base : Theme.text
            font.pixelSize: 13
        }
        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: QuickSettings.tab = tabItem.tab
        }
    }
}
