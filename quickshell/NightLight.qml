pragma Singleton

// Luz noturna (hyprsunset), ligada/desligada pela central de controle.
// O hyprsunset segue os horários de hypr/hyprsunset.conf; aqui só liga/desliga na hora.
// Obs.: depois de "identity" o hyprsunset ainda informa a última temperatura, então o estado
// fica guardado aqui (começa ligado se a temperatura atual for quente).

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool on: false
    property int temperature: 4500     // a usada ao religar

    function toggle() {
        if (on) {
            Quickshell.execDetached(["hyprctl", "hyprsunset", "identity"]);
            on = false;
        } else {
            Quickshell.execDetached(["hyprctl", "hyprsunset", "temperature", String(temperature)]);
            on = true;
        }
    }

    Process {
        running: true
        command: ["hyprctl", "hyprsunset", "temperature"]
        stdout: StdioCollector {
            onStreamFinished: {
                const t = parseInt(text.trim());
                if (!isNaN(t) && t < 6000) {
                    root.temperature = t;
                    root.on = true;
                }
            }
        }
    }
}
