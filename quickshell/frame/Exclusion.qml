// Reserva espaço numa borda da tela para as janelas não ficarem embaixo da moldura.
// É uma janela invisível e sem cliques; só o "exclusiveZone" importa.

import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    property string edge: "top"   // top | bottom | left | right
    property int size: 8

    anchors.top: edge !== "bottom"
    anchors.bottom: edge !== "top"
    anchors.left: edge !== "right"
    anchors.right: edge !== "left"
    implicitWidth: 1
    implicitHeight: 1
    color: "transparent"
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: size
    WlrLayershell.namespace: "moldura-reserva"
    WlrLayershell.layer: WlrLayer.Bottom
    mask: Region {}
}
