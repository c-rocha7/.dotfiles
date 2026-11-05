// Aba Wi-Fi do painel de conexões.
// - interruptor liga/desliga o Wi-Fi
// - lista de redes: conectada primeiro, depois salvas, depois pelo sinal
// - clique numa rede: conecta (pede a senha se for nova e protegida)
// - rede conectada: "Desconectar"; rede salva: lixeira para esquecer
// Redes corporativas (WPA-Enterprise) e VPN: "Mais opções" abre o nm-connection-editor.

import QtQuick
import Quickshell
import Quickshell.Networking
import qs

Column {
    id: root

    // Ativo enquanto a aba está visível (liga a busca de redes).
    property bool active: false

    readonly property var device: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var networks: {
        if (!device)
            return [];
        return device.networks.values
            .filter(n => n.name !== "")
            .sort((a, b) => (b.connected - a.connected) || (b.known - a.known) || (b.signalStrength - a.signalStrength));
    }

    // Rede que está pedindo senha e a última mensagem de erro.
    property string askingPassword: ""
    property string error: ""

    spacing: 10

    // Busca redes só enquanto o painel está aberto (economiza bateria).
    Binding {
        target: root.device
        property: "scannerEnabled"
        value: root.active && Networking.wifiEnabled
        when: root.device !== null
    }

    onActiveChanged: if (!active) {
        askingPassword = "";
        error = "";
    }

    function signalIcon(net) {
        const s = net.signalStrength;
        const secured = net.security !== WifiSecurityType.Open;
        const level = s > 0.75 ? 3 : s > 0.5 ? 2 : s > 0.25 ? 1 : 0;
        return secured ? ["\u{f0921}", "\u{f0924}", "\u{f0927}", "\u{f092a}"][level]
                       : ["\u{f091f}", "\u{f0922}", "\u{f0925}", "\u{f0928}"][level];
    }

    function activate(net) {
        error = "";
        if (net.connected)
            return;
        const psk = [WifiSecurityType.WpaPsk, WifiSecurityType.Wpa2Psk, WifiSecurityType.Sae];
        if (net.known || net.security === WifiSecurityType.Open)
            net.connect();
        else if (psk.includes(net.security))
            askingPassword = net.name;
        else
            Quickshell.execDetached(["nm-connection-editor"]);
    }

    function failText(reason) {
        if (reason === ConnectionFailReason.NoSecrets)
            return "Senha necessária ou incorreta.";
        if (reason === ConnectionFailReason.WifiAuthTimeout)
            return "Tempo esgotado na autenticação (senha incorreta?).";
        if (reason === ConnectionFailReason.WifiNetworkLost)
            return "Rede fora de alcance.";
        return "Não foi possível conectar.";
    }

    // Cabeçalho: Wi-Fi + interruptor
    Item {
        width: parent.width
        height: 26

        ThemedText {
            anchors.verticalCenter: parent.verticalCenter
            text: !Networking.wifiEnabled ? "Wi-Fi desligado"
                : root.device?.connected ? "Wi-Fi conectado" : "Wi-Fi"
            color: Theme.subtext
            font.pixelSize: 12
        }
        Toggle {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            checked: Networking.wifiEnabled
            onToggled: Networking.wifiEnabled = !Networking.wifiEnabled
        }
    }

    ThemedText {
        visible: root.error !== ""
        width: parent.width
        wrapMode: Text.Wrap
        text: root.error
        color: Theme.red
        font.pixelSize: 12
    }

    // Lista de redes
    Flickable {
        id: flick
        visible: Networking.wifiEnabled
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
                model: root.networks

                WifiRow {
                    required property var modelData
                    width: list.width
                    net: modelData
                }
            }

            ThemedText {
                visible: root.networks.length === 0
                width: parent.width
                topPadding: 10
                bottomPadding: 10
                horizontalAlignment: Text.AlignHCenter
                text: "Procurando redes…"
                color: Theme.overlay
                font.weight: Font.Normal
            }
        }
    }

    SmallButton {
        text: "Mais opções (VPN, redes corporativas)…"
        onClicked: {
            Quickshell.execDetached(["nm-connection-editor"]);
            QuickSettings.close();
        }
    }

    // Uma rede da lista.
    component WifiRow: Rectangle {
        id: row

        property var net
        readonly property bool asking: root.askingPassword === net.name

        implicitHeight: content.implicitHeight + 12
        radius: 10
        color: net.connected ? Theme.surface1 : rowMouse.containsMouse ? Theme.base : "transparent"

        Connections {
            target: row.net
            function onConnectionFailed(reason) {
                root.error = `${row.net.name}: ${root.failText(reason)}`;
                if (reason === ConnectionFailReason.NoSecrets && !row.net.known)
                    root.askingPassword = row.net.name;
            }
            function onConnectedChanged() {
                if (row.net.connected) {
                    root.error = "";
                    if (row.asking)
                        root.askingPassword = "";
                }
            }
        }

        MouseArea {
            id: rowMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: row.net.connected ? Qt.ArrowCursor : Qt.PointingHandCursor
            onClicked: root.activate(row.net)
        }

        Column {
            id: content
            x: 10
            y: 6
            width: parent.width - 20
            spacing: 6

            Item {
                width: parent.width
                height: 26

                BarText {
                    id: icon
                    text: root.signalIcon(row.net)
                    color: row.net.connected ? Theme.blue : Theme.text
                }
                Column {
                    anchors.left: icon.right
                    anchors.leftMargin: 10
                    anchors.right: actions.left
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter

                    ThemedText {
                        width: parent.width
                        elide: Text.ElideRight
                        text: row.net.name
                    }
                    ThemedText {
                        visible: text !== ""
                        text: row.net.stateChanging ? "Conectando…"
                            : row.net.connected ? "Conectado"
                            : row.net.known ? "Salva" : ""
                        color: row.net.connected ? Theme.blue : Theme.overlay
                        font.pixelSize: 11
                        font.weight: Font.Normal
                    }
                }
                Row {
                    id: actions
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6

                    SmallButton {
                        visible: row.net.connected
                        text: "Desconectar"
                        onClicked: row.net.disconnect()
                    }
                    SmallButton {
                        visible: row.net.known
                        text: "" // lixeira: esquecer a rede
                        hoverColor: Theme.red
                        onClicked: row.net.forget()
                    }
                }
            }

            // Campo de senha (rede nova e protegida)
            Rectangle {
                visible: row.asking
                width: parent.width
                height: 32
                radius: 8
                color: Theme.island

                TextInput {
                    id: password
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    verticalAlignment: TextInput.AlignVCenter
                    echoMode: TextInput.Password
                    color: Theme.text
                    font.family: Theme.font
                    font.pixelSize: 13
                    clip: true
                    onVisibleChanged: if (visible) { text = ""; forceActiveFocus(); }
                    onAccepted: if (text !== "") row.net.connectWithPsk(text)
                    Keys.onEscapePressed: root.askingPassword = ""

                    ThemedText {
                        visible: password.text === ""
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Senha (Enter para conectar)"
                        color: Theme.overlay
                        font.pixelSize: 12
                        font.weight: Font.Normal
                    }
                }
            }
        }
    }
}
