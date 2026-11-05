pragma Singleton

// Atualizações pendentes: sistema (checkupdates, sem root), AUR (yay -Qua) e Flatpak.
// - confere 1 min depois de abrir e depois a cada hora
// - count / repo / aur / flatpak: usados pela UpdatesPill (ilha aberta)
// - run(): abre o terminal com a função "atualizar" do zsh (zsh/.zshrc), que ao terminar
//   chama "qs ipc call updates refresh" para zerar o contador
// Obs.: atualizações do Nix e do mise não entram na conta (o "atualizar" cuida delas também).

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property int repo: 0
    property int aur: 0
    property int flatpak: 0
    readonly property int count: repo + aur + flatpak
    property bool checking: false
    property date lastCheck

    function check() {
        if (!proc.running)
            proc.running = true;
    }

    function run() {
        Quickshell.execDetached(["ghostty", "--title=Atualizar", "-e", "zsh", "-ic",
            "atualizar; echo; read -k1 '?Pressione uma tecla para fechar'"]);
    }

    // Uma seção por fonte; "checkupdates" sai com código 2 quando não há nada (não é erro).
    Process {
        id: proc
        command: ["bash", "-c",
            "echo '#repo'; checkupdates 2>/dev/null;" +
            "echo '#aur'; yay -Qua 2>/dev/null;" +
            "echo '#flatpak'; flatpak remote-ls --updates --columns=application 2>/dev/null; true"]
        onRunningChanged: root.checking = running
        stdout: StdioCollector {
            onStreamFinished: {
                const counts = { repo: 0, aur: 0, flatpak: 0 };
                let section = "";
                for (const line of text.split("\n")) {
                    if (line.startsWith("#"))
                        section = line.slice(1);
                    else if (line.trim() !== "" && section in counts)
                        counts[section]++;
                }
                root.repo = counts.repo;
                root.aur = counts.aur;
                root.flatpak = counts.flatpak;
                root.lastCheck = new Date();
            }
        }
    }

    Timer {
        interval: 60 * 1000
        running: true
        onTriggered: root.check()
    }
    Timer {
        interval: 60 * 60 * 1000
        running: true
        repeat: true
        onTriggered: root.check()
    }

    IpcHandler {
        target: "updates"

        // qs ipc prop get updates count
        readonly property int count: root.count

        function refresh(): void { root.check(); }
        function run(): void { root.run(); }
    }
}
