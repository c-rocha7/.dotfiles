// Layout "moldura" de um monitor: reserva de espaço nas 4 bordas + a janela da moldura.

import QtQuick
import Quickshell
import qs

Scope {
    id: root

    required property var modelData

    Exclusion { screen: root.modelData; edge: "top"; size: Theme.frameBar }
    Exclusion { screen: root.modelData; edge: "bottom"; size: Theme.frameBorder }
    Exclusion { screen: root.modelData; edge: "left"; size: Theme.frameBorder }
    Exclusion { screen: root.modelData; edge: "right"; size: Theme.frameBorder }

    FrameWindow {
        modelData: root.modelData
    }
}
