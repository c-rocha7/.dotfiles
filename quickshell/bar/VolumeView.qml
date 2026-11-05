// Aviso de volume: ícone, barra e porcentagem (ou "mudo").

import QtQuick
import Quickshell.Services.Pipewire
import qs

LevelView {
    id: root

    property PwNode sink
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false

    icon: muted ? "\u{f0581}" : volume < 0.5 ? "" : ""
    value: volume
    label: muted ? "mudo" : Math.round(volume * 100) + "%"
    dim: muted
}
