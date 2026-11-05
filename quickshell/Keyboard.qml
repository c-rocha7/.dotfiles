pragma Singleton

// Estado do Caps Lock, lido da luz do próprio teclado
// (/sys/class/leds/*::capslock/brightness), a cada 250 ms.
// Funciona venha a mudança de onde vier (tecla, outro teclado, etc.).

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool capsLock: false
    property bool quiet: true // a primeira leitura (ao iniciar) não mostra aviso
    property string ledPath: ""

    // Emitido quando o Caps Lock muda (a ilha mostra o aviso).
    signal capsUpdated

    // Descobre o arquivo da luz do Caps Lock (o número "inputN" muda entre máquinas).
    Process {
        running: true
        command: ["bash", "-c", "for f in /sys/class/leds/*::capslock/brightness; do [ -e \"$f\" ] && echo \"$f\" && break; done"]
        stdout: StdioCollector {
            onStreamFinished: root.ledPath = text.trim()
        }
    }

    FileView {
        id: led
        path: root.ledPath
        onLoaded: {
            const on = text().trim() !== "0";
            if (on !== root.capsLock) {
                root.capsLock = on;
                if (!root.quiet)
                    root.capsUpdated();
            }
            root.quiet = false;
        }
    }

    Timer {
        interval: 250
        repeat: true
        running: root.ledPath !== ""
        onTriggered: led.reload()
    }
}
