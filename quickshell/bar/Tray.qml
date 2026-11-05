// Bandeja do sistema (ícones de apps como Discord, Steam, etc.).
// Clique esquerdo: abre o app (ou o menu, se o app só tiver menu, ex.: Wi-Fi).
// Clique direito: menu do app (ex.: fechar o Spotify/Vesktop, trocar de Wi-Fi).
// Meio: ação secundária.
// Some quando não há nenhum ícone.

import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs

Pill {
    id: root

    // Janela da barra, necessária para posicionar os menus.
    required property var bar

    // Ícones escondidos (já têm um bloco próprio na ilha).
    // "blueman" e "nm-applet": continuam rodando (janelas de PIN e de senha especial),
    // só some o ícone; o painel de conexões da ilha faz o resto.
    readonly property var hiddenIds: ["blueman", "nm-applet"]

    visible: SystemTray.items.values.some(item => !hiddenIds.includes(item.id))
    spacing: 10


    Repeater {
        model: SystemTray.items

        IconImage {
            id: icon

            required property SystemTrayItem modelData

            visible: !root.hiddenIds.includes(modelData.id)
            source: modelData.icon
            implicitSize: 14
            anchors.verticalCenter: parent.verticalCenter

            // Menu do app, aberto logo abaixo do ícone.
            // Enquanto estiver aberto, a ilha não fecha (senão o menu sumia junto).
            QsMenuAnchor {
                id: menu
                menu: icon.modelData.menu
                anchor.item: icon
                anchor.edges: Edges.Bottom
                anchor.gravity: Edges.Bottom
                anchor.margins.top: 10
                onOpened: root.bar.menuOpen = true
                onClosed: root.bar.menuOpen = false
            }

            MouseArea {
                anchors.fill: parent
                anchors.margins: -4
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                cursorShape: Qt.PointingHandCursor

                onClicked: mouse => {
                    const item = icon.modelData;
                    if (mouse.button === Qt.LeftButton && !item.onlyMenu) {
                        item.activate();
                    } else if (mouse.button === Qt.MiddleButton) {
                        item.secondaryActivate();
                    } else if (item.hasMenu) {
                        menu.open();
                    }
                }
            }
        }
    }
}
