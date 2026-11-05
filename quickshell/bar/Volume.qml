// Volume da saída de som e do microfone (via PipeWire).
// Clique esquerdo: abre o pavucontrol. Clique direito: muta/desmuta.
// Rolagem: aumenta/diminui 5%.

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import qs

Pill {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink     // alto-falante/fone
    readonly property PwNode source: Pipewire.defaultAudioSource // microfone

    readonly property int volume: Math.round((sink?.audio?.volume ?? 0) * 100)
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property int micVolume: Math.round((source?.audio?.volume ?? 0) * 100)
    readonly property bool micMuted: source?.audio?.muted ?? false

    clickable: true

    // Sem isso o PipeWire não envia os dados (volume, mudo) desses dispositivos.
    PwObjectTracker {
        objects: [root.sink, root.source]
    }

    BarText {
        text: root.muted ? "\u{f0581} 0%"
                         : (root.volume < 50 ? "" : "") + " " + root.volume + "%"
    }

    BarText {
        text: (root.micMuted ? "" : "") + " " + root.micVolume + "%"
    }

    onClicked: mouse => {
        if (mouse.button === Qt.RightButton) {
            if (sink?.audio)
                sink.audio.muted = !sink.audio.muted;
        } else {
            Quickshell.execDetached(["pavucontrol"]);
        }
    }

    onScrolled: wheel => {
        if (!sink?.audio)
            return;
        const step = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
        sink.audio.volume = Math.max(0, Math.min(1, sink.audio.volume + step));
    }
}
