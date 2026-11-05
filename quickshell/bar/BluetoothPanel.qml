// Aba Bluetooth do painel de conexões.
// - interruptor liga/desliga o Bluetooth
// - busca dispositivos enquanto a aba está aberta
// - clique: conecta / desconecta; dispositivo novo: pareia e conecta
// - lixeira: esquece (despareia) o dispositivo
// Janelas de PIN/confirmação de pareamento vêm do blueman-applet (rodando escondido).

import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Widgets
import qs

Column {
    id: root

    property bool active: false

    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
    readonly property bool powered: adapter?.enabled ?? false
    readonly property var devices: {
        if (!adapter)
            return [];
        return adapter.devices.values
            .filter(d => d.paired || d.name !== d.address) // esconde aparelhos sem nome
            .sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired) || a.name.localeCompare(b.name));
    }

    // Dispositivos que estamos pareando (para conectar logo depois).
    property var pairing: []

    spacing: 10

    // Procura aparelhos só enquanto a aba está aberta.
    Binding {
        target: root.adapter
        property: "discovering"
        value: root.active && root.powered
        when: root.adapter !== null
    }

    // Cabeçalho: Bluetooth + interruptor
    Item {
        width: parent.width
        height: 26

        ThemedText {
            anchors.verticalCenter: parent.verticalCenter
            text: !root.powered ? "Bluetooth desligado"
                : root.adapter.discovering ? "Bluetooth · procurando aparelhos…" : "Bluetooth"
            color: Theme.subtext
            font.pixelSize: 12
        }
        Toggle {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            checked: root.powered
            onToggled: if (root.adapter) root.adapter.enabled = !root.adapter.enabled
        }
    }

    Flickable {
        id: flick
        visible: root.powered
        width: parent.width
        height: Math.min(list.implicitHeight, 330)
        contentHeight: list.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: list
            width: flick.width
            spacing: 4

            Repeater {
                model: root.devices

                DeviceRow {
                    required property var modelData
                    width: list.width
                    device: modelData
                }
            }

            ThemedText {
                visible: root.devices.length === 0
                width: parent.width
                topPadding: 10
                bottomPadding: 10
                horizontalAlignment: Text.AlignHCenter
                text: "Nenhum aparelho encontrado ainda"
                color: Theme.overlay
                font.weight: Font.Normal
            }
        }
    }

    SmallButton {
        text: "Mais opções (blueman)…"
        onClicked: {
            Quickshell.execDetached(["blueman-manager"]);
            QuickSettings.close();
        }
    }

    // Um aparelho da lista.
    component DeviceRow: Rectangle {
        id: row

        property var device

        implicitHeight: 44
        radius: 10
        color: device.connected ? Theme.surface1 : rowMouse.containsMouse ? Theme.base : "transparent"

        // Terminou de parear: confia no aparelho e conecta.
        Connections {
            target: row.device
            function onPairedChanged() {
                if (row.device.paired && root.pairing.includes(row.device.address)) {
                    root.pairing = root.pairing.filter(a => a !== row.device.address);
                    row.device.trusted = true;
                    row.device.connect();
                }
            }
        }

        MouseArea {
            id: rowMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                const d = row.device;
                if (d.connected) {
                    d.disconnect();
                } else if (d.paired) {
                    d.connect();
                } else if (!d.pairing) {
                    root.pairing = [...root.pairing, d.address];
                    d.pair();
                }
            }
        }

        IconImage {
            id: icon
            x: 10
            anchors.verticalCenter: parent.verticalCenter
            implicitSize: 22
            source: Quickshell.iconPath(row.device.icon || "bluetooth", "bluetooth")
        }

        Column {
            anchors.left: icon.right
            anchors.leftMargin: 10
            anchors.right: forget.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter

            ThemedText {
                width: parent.width
                elide: Text.ElideRight
                text: row.device.name
            }
            ThemedText {
                text: {
                    const d = row.device;
                    if (d.pairing)
                        return "Pareando…";
                    if (d.state === BluetoothDeviceState.Connecting)
                        return "Conectando…";
                    if (d.connected)
                        return "Conectado" + (d.batteryAvailable ? ` · bateria ${Math.round(d.battery * 100)}%` : "");
                    return d.paired ? "Pareado" : "Disponível · clique para parear";
                }
                color: row.device.connected ? Theme.blue : Theme.overlay
                font.pixelSize: 11
                font.weight: Font.Normal
            }
        }

        SmallButton {
            id: forget
            visible: row.device.paired
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            text: "" // lixeira: esquecer o aparelho
            hoverColor: Theme.red
            onClicked: row.device.forget()
        }
    }
}
