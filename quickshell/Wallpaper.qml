pragma Singleton

// Troca de wallpaper pela ilha (sem abrir o waypaper).
// - images: [{ path, thumb }] da pasta ~/Imagens/Wallpapers (miniaturas no cache)
// - current: wallpaper atual (awww query)
// - apply(): usa `waypaper --wallpaper`, que faz a transição e salva a escolha
//   (o `waypaper --restore` do login e a tela de bloqueio usam o mesmo)
//
//   qs ipc call wallpaper toggle   abre/fecha o painel (SUPER+W)
//   qs ipc call wallpaper random   troca por um aleatório

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string folder: Quickshell.env("HOME") + "/Imagens/Wallpapers"
    readonly property string thumbDir: Quickshell.cachePath("wallpapers")

    property bool open: false
    property var images: []
    property string current: ""

    // Troca automática: 0 = desligada; senão, minutos entre as trocas (aleatório). Salvo em
    // ~/.local/state/quickshell/.../wallpaper.json (vale depois de reiniciar). As cores do
    // sistema acompanham (o waypaper roda o matugen).
    readonly property var autoOptions: [0, 30, 60, 180]
    readonly property int autoMinutes: settings.autoMinutes
    function cycleAuto() {
        const i = autoOptions.indexOf(settings.autoMinutes);
        settings.autoMinutes = autoOptions[(i + 1) % autoOptions.length];
        settingsFile.writeAdapter();
    }
    function autoLabel() {
        const m = settings.autoMinutes;
        return m === 0 ? "desligado" : m < 60 ? `${m} min` : `${m / 60} h`;
    }
    FileView {
        id: settingsFile
        path: Quickshell.statePath("wallpaper.json")
        printErrors: false
        JsonAdapter {
            id: settings
            property int autoMinutes: 0
        }
    }
    Timer {
        running: settings.autoMinutes > 0
        interval: Math.max(1, settings.autoMinutes) * 60 * 1000
        repeat: true
        onTriggered: {
            if (root.images.length === 0) {
                root.refresh();
                randomWhenReady.start();
            } else {
                root.random();
            }
        }
    }

    function show() {
        Launcher.close();
        PowerMenu.close();
        QuickSettings.close();
        Cheatsheet.close();
        Recorder.pickerOpen = false;
        NotificationService.centerOpen = false;
        refresh();
        open = true;
    }

    function close() {
        open = false;
    }

    // Só lê o wallpaper atual (usado também pela visão geral das workspaces)
    function readCurrent() {
        currentReader.running = true;
    }

    function refresh() {
        currentReader.running = true;
        if (!scanner.running) {
            pendingImages = [];
            scanner.running = true;
        }
    }

    function apply(path) {
        current = path;
        Quickshell.execDetached(["waypaper", "--wallpaper", path]);
        // As cores do sistema seguem o wallpaper: o waypaper roda o matugen/aplicar.sh (post_command)
    }

    function random() {
        const others = images.filter(i => i.path !== current);
        if (others.length > 0)
            apply(others[Math.floor(Math.random() * others.length)].path);
    }

    // A lista é montada aos poucos (as miniaturas aparecem conforme ficam prontas).
    property var pendingImages: []

    Process {
        id: scanner
        command: ["bash", Quickshell.shellPath("scripts/wallpaper-thumbs.sh"), root.folder, root.thumbDir]
        stdout: SplitParser {
            onRead: line => {
                const tab = line.indexOf("\t");
                if (tab < 0)
                    return;
                root.pendingImages.push({ path: line.slice(0, tab), thumb: line.slice(tab + 1) });
                // Publica em lotes de 4 para não redesenhar a cada linha.
                if (root.pendingImages.length % 4 === 0 || root.images.length === 0)
                    root.images = root.pendingImages.slice();
            }
        }
        onExited: root.images = root.pendingImages.slice()
    }

    // "eDP-1: 1920x1080, ..., currently displaying: image: /caminho"
    Process {
        id: currentReader
        command: ["awww", "query"]
        stdout: StdioCollector {
            onStreamFinished: {
                const m = text.match(/image: (.+)$/m);
                if (m)
                    root.current = m[1].trim();
            }
        }
    }

    IpcHandler {
        target: "wallpaper"

        function toggle(): void {
            if (root.open)
                root.close();
            else
                root.show();
        }
        function random(): void {
            if (root.images.length === 0) {
                root.refresh();
                randomWhenReady.start();
            } else {
                root.random();
            }
        }
    }

    // "random" antes de a lista existir: espera a primeira leitura.
    Timer {
        id: randomWhenReady
        interval: 300
        repeat: true
        onTriggered: {
            if (!scanner.running) {
                stop();
                root.random();
            }
        }
    }
}
