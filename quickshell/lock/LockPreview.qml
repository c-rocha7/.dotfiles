// Prévia da tela de bloqueio por cima de tudo, SEM bloquear a sessão (para testar o visual).
// Abre com: qs ipc call lock previa · fecha com Esc ou Enter.

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs

PanelWindow {
    required property var modelData
    screen: modelData

    visible: Lock.previewOpen
    color: Theme.island
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "lock-previa"
    WlrLayershell.keyboardFocus: Lock.previewOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    LockSurface {
        anchors.fill: parent
        preview: true
        focus: true
    }
}
