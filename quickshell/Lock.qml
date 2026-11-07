pragma Singleton

// Tela de bloqueio: estado e verificação da senha (PAM).
// - Bloqueia pelo protocolo seguro do Wayland (ext-session-lock): veja lock/LockScreen.qml.
// - A senha é conferida pelo PAM com /etc/pam.d/hyprlock ("auth include login").
// - O estado "bloqueado" sobrevive a um recarregamento da config (PersistentProperties).
// - Não existe comando para desbloquear sem senha.
//
//   qs ipc call lock lock   bloqueia (o hypridle chama isso; loginctl lock-session também)

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam

Singleton {
    id: root

    readonly property bool locked: persist.locked
    property string wallpaper: ""
    property string status: ""   // mensagem para o usuário (ex.: senha incorreta)
    property bool busy: false    // conferindo a senha
    property int failures: 0
    property bool previewOpen: false   // prévia da tela de bloqueio, sem bloquear (Esc fecha)
    property string pending: ""  // senha aguardando o pedido do PAM (apagada logo depois)

    // Emitido quando a senha está errada (a tela faz o campo "tremer").
    signal failed

    PersistentProperties {
        id: persist
        reloadableId: "lockState"
        property bool locked: false
    }

    function lock() {
        if (persist.locked)
            return;
        status = "";
        failures = 0;
        Launcher.close();
        PowerMenu.close();
        QuickSettings.close();
        Cheatsheet.close();
        NotificationService.centerOpen = false;
        Recorder.pickerOpen = false;
        Wallpaper.close();
        wallpaperReader.running = true;
        persist.locked = true;
    }

    function submit(password) {
        if (busy || password === "")
            return;
        busy = true;
        status = "";
        pending = password;
        pam.start();
    }

    PamContext {
        id: pam
        config: "hyprlock"

        // O PAM pede a senha: responde e esquece.
        onResponseRequiredChanged: {
            if (responseRequired) {
                respond(root.pending);
                root.pending = "";
            }
        }

        onCompleted: result => {
            root.busy = false;
            root.pending = "";
            if (result === PamResult.Success) {
                root.failures = 0;
                root.status = "";
                persist.locked = false;
                // Avisa o logind (sinal "Unlock"): o SUPER+L/hypridle bloqueiam por ele, e quem
                // escuta o bloqueio (ex.: a minitela, que apaga) precisa saber que desbloqueou.
                Quickshell.execDetached(["loginctl", "unlock-session"]);
            } else {
                root.failures += 1;
                // O Arch (pam_faillock) bloqueia a conta por 10 min após 3 senhas erradas
                // em 15 min; nesse tempo até a senha certa é recusada.
                root.status = root.failures >= 3 || result === PamResult.MaxTries
                    ? "3 senhas erradas: aguarde 10 minutos e tente de novo"
                    : `Senha incorreta (${root.failures} de 3)`;
                root.failed();
            }
        }

        onError: error => {
            root.busy = false;
            root.pending = "";
            root.status = "Erro ao verificar a senha";
            root.failed();
        }
    }

    // Wallpaper atual (o awww responde "…currently displaying: image: /caminho").
    Process {
        id: wallpaperReader
        command: ["awww", "query"]
        stdout: StdioCollector {
            onStreamFinished: {
                const m = text.match(/image: (.+)$/m);
                if (m)
                    root.wallpaper = m[1].trim();
            }
        }
    }

    IpcHandler {
        target: "lock"

        function lock(): void { root.lock(); }
        // Mostra como a tela de bloqueio está, sem bloquear: qs ipc call lock previa
        function previa(): void {
            wallpaperReader.running = true;
            root.previewOpen = true;
        }
        function fecharPrevia(): void { root.previewOpen = false; }
    }
}
