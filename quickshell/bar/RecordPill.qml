// Indicador de gravação: ponto vermelho piscando + tempo.
// Com "stoppable", vira um botão "Parar" (usado na ilha aberta).

import QtQuick
import Quickshell
import qs

Pill {
    id: root

    property bool stoppable: false

    visible: Recorder.recording
    clickable: stoppable
    color: stoppable && hovered ? Theme.red : Theme.base

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
        enabled: Recorder.recording
    }

    readonly property int elapsed: Math.max(0, Math.floor((clock.date - Recorder.startedAt) / 1000))

    Rectangle {
        width: 8
        height: 8
        radius: 4
        anchors.verticalCenter: parent.verticalCenter
        color: root.stoppable && root.hovered ? Theme.base : Theme.red

        SequentialAnimation on opacity {
            running: Recorder.recording
            loops: Animation.Infinite
            NumberAnimation { to: 0.3; duration: 700 }
            NumberAnimation { to: 1; duration: 700 }
        }
    }

    BarText {
        text: {
            const m = Math.floor(root.elapsed / 60), s = root.elapsed % 60;
            return `${m}:${String(s).padStart(2, "0")}` + (root.stoppable ? "  Parar" : "");
        }
        color: root.stoppable && root.hovered ? Theme.base : Theme.text
    }

    onClicked: Recorder.stop()
}
