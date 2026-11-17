pragma Singleton

// Atualizações pendentes: sistema (checkupdates, sem root), AUR (yay -Qua) e Flatpak.
// - confere 1 min depois de abrir e depois a cada hora
// - count / repo / aur / flatpak: usados pela UpdatesPill (barra)
// - packages: lista { name, from, to, source } mostrada no painel (bar/UpdatesView.qml)
// - open: painel aberto (clique na UpdatesPill ou "qs ipc call updates toggle")
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
    property var packages: []          // { name, from, to, source: "repo" | "aur" | "flatpak" }
    property bool checking: false
    property date lastCheck
    property bool open: false

    function toggle() { open = !open; }
    function close() { open = false; }

    function check() {
        if (!proc.running)
            proc.running = true;
    }

    function run() {
        root.open = false;
        Quickshell.execDetached(["ghostty", "--title=Atualizar", "-e", "zsh", "-ic",
            "atualizar; echo; read -k1 '?Pressione uma tecla para fechar'"]);
    }

    // Uma seção por fonte; "checkupdates" sai com código 2 quando não há nada (não é erro).
    Process {
        id: proc
        command: ["bash", "-c",
            "echo '#repo'; checkupdates 2>/dev/null;" +
            "echo '#aur'; yay -Qua 2>/dev/null;" +
            "echo '#flatpak'; flatpak remote-ls --updates --columns=name,application,version 2>/dev/null; true"]
        onRunningChanged: root.checking = running
        stdout: StdioCollector {
            onStreamFinished: {
                const counts = { repo: 0, aur: 0, flatpak: 0 };
                const list = [];
                let section = "";
                for (const line of text.split("\n")) {
                    if (line.startsWith("#")) {
                        section = line.slice(1);
                        continue;
                    }
                    if (line.trim() === "" || !(section in counts))
                        continue;
                    counts[section]++;
                    if (section === "flatpak") {
                        // nome<TAB>id<TAB>versão (a versão costuma vir vazia)
                        const f = line.split("\t");
                        list.push({ name: f[0] || f[1], from: "", to: f[2] ?? "", source: section, id: f[1] ?? "" });
                    } else {
                        // "pacote antiga -> nova"
                        const m = line.trim().match(/^(\S+)\s+(\S+)\s+->\s+(\S+)/);
                        if (m)
                            list.push({ name: m[1], from: m[2], to: m[3], source: section, id: "" });
                        else
                            list.push({ name: line.trim(), from: "", to: "", source: section, id: "" });
                    }
                }
                root.repo = counts.repo;
                root.aur = counts.aur;
                root.flatpak = counts.flatpak;
                root.packages = list;
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
        readonly property bool open: root.open

        function refresh(): void { root.check(); }
        function run(): void { root.run(); }
        function toggle(): void { root.toggle(); }
    }
}
