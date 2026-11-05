pragma Singleton

// GameMode (jogos): avisado pelo ~/.dotfiles/gamemode/hook.sh via "qs ipc call gamemode started|stopped".
// - liga o perfil Desempenho enquanto o jogo roda e volta ao anterior no fim
// - "active": usado pela ilha (aviso + ícone de controle)
// Se o carregador for colocado/tirado no meio do jogo, o Battery.qml troca o "restoreTo"
// (o perfil que volta no fim) em vez de mexer no perfil atual.

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

Singleton {
    id: root

    property bool active: false
    property int restoreTo: PowerProfile.Balanced

    signal toggled

    function start() {
        if (active)
            return;
        restoreTo = PowerProfiles.profile;
        PowerProfiles.profile = PowerProfile.Performance;
        active = true;
        toggled();
    }

    function stop() {
        if (!active)
            return;
        PowerProfiles.profile = restoreTo;
        active = false;
        toggled();
    }

    // Se o Quickshell reiniciar no meio de um jogo, retoma o estado (o perfil já está em Desempenho).
    Process {
        running: true
        command: ["gamemoded", "-s"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.includes("is active")) {
                    root.restoreTo = Battery.pluggedIn ? PowerProfile.Balanced : PowerProfile.PowerSaver;
                    root.active = true;
                }
            }
        }
    }

    IpcHandler {
        target: "gamemode"

        function started(): void { root.start(); }
        function stopped(): void { root.stop(); }
    }
}
