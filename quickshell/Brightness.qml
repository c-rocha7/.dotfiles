pragma Singleton

// Brilho da tela, na mesma escala dos atalhos (hypr/scripts/brightness.sh):
// 0% = mínimo útil da tela, 100% = máximo, passos de 5%.
// O Linux não avisa quando o brilho muda, então o script avisa a ilha com:
//   qs ipc call brightness changed

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property real value: 0 // de 0 a 1

    // Emitido depois de ler o brilho novo (a ilha mostra o aviso).
    signal updated

    function refresh() {
        reader.running = true;
    }

    // Define o brilho (0–100, na mesma escala dos atalhos). Usado pelo controle da central.
    function set(pct) {
        setter.command = ["bash", "-c", `~/.config/hypr/scripts/brightness.sh set ${Math.round(pct)}`];
        setter.running = true;
    }

    Process {
        id: setter
    }

    // "brightness.sh get" devolve a porcentagem na escala do script (0–100).
    Process {
        id: reader
        command: ["bash", "-c", "~/.config/hypr/scripts/brightness.sh get"]
        stdout: StdioCollector {
            onStreamFinished: {
                const pct = parseInt(text.trim());
                if (isNaN(pct))
                    return;
                root.value = pct / 100;
                root.updated();
            }
        }
    }

    IpcHandler {
        target: "brightness"

        function changed(): void { root.refresh(); }
    }
}
