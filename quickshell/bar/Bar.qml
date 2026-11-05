// Janela da ilha dinâmica.
// A janela é grande e transparente para caber a ilha expandida, mas:
// - só a ilha recebe cliques (mask), o resto passa para as janelas de baixo;
// - só o tamanho da ilha fechada é reservado no topo (exclusiveZone);
// - só pega o teclado com o launcher ou o painel de notificações aberto.

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs

PanelWindow {
    id: bar

    // Monitor desta barra (vem do Variants em shell.qml).
    required property var modelData
    screen: modelData

    anchors.top: true
    implicitWidth: 1140 // largura máxima da ilha aberta (o guia de atalhos é o maior)
    implicitHeight: 700 // altura máxima da ilha aberta
    color: "transparent"

    // Um menu da bandeja está aberto (a ilha fica aberta até ele fechar).
    property bool menuOpen: false

    exclusionMode: ExclusionMode.Normal
    exclusiveZone: Theme.islandTop + Theme.barHeight

    // Teclado só com o launcher ou o painel aberto ("OnDemand": o "Exclusive"
    // fazia o Hyprland desfazer o focus grab e fechar o launcher na hora).
    WlrLayershell.keyboardFocus: island.launcherOpen || island.recordOpen || island.wallpaperOpen || island.keysOpen || island.powerOpen || island.centerOpen || island.connectionsOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    mask: Region {
        item: island
    }

    Island {
        id: island
        window: bar
        anchors.top: parent.top
        anchors.topMargin: Theme.islandTop
        anchors.horizontalCenter: parent.horizontalCenter
    }
}
