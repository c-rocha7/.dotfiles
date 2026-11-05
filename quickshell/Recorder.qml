pragma Singleton

// Gravação de tela (usa ~/.config/hypr/scripts/record.sh).
// - pickerOpen/mode: seletor de áudio aberto na ilha antes de gravar ("region" ou "screen")
// - audio: última escolha ("none", "desktop", "both"), lembrada entre reinícios
// - recording/startedAt: estado da gravação (o script avisa via IPC)
//
//   qs ipc call recording toggle region   SUPER+R: abre o seletor, ou para se estiver gravando
//   qs ipc call recording toggle screen   SUPER+SHIFT+R

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string script: "~/.config/hypr/scripts/record.sh"

    property bool pickerOpen: false
    property string mode: "region"
    property string audio: "desktop"

    property bool recording: false
    property date startedAt: new Date()

    readonly property var audioOptions: [
        { id: "none", name: "Sem áudio", glyph: "\u{f075f}" },
        { id: "desktop", name: "Som do PC", glyph: "" },
        { id: "both", name: "PC + microfone", glyph: "" }
    ]

    function toggle(newMode) {
        if (recording) {
            stop();
            return;
        }
        mode = newMode;
        Launcher.close();
        PowerMenu.close();
        QuickSettings.close();
        Cheatsheet.close();
        Wallpaper.close();
        NotificationService.centerOpen = false;
        pickerOpen = true;
    }

    function start(audioId) {
        audio = audioId;
        audioFile.setText(audioId);
        pickerOpen = false;
        Quickshell.execDetached(["bash", "-c", `${script} start "$1" "$2"`, "_", mode, audioId]);
    }

    function stop() {
        Quickshell.execDetached(["bash", "-c", `${script} stop`]);
    }

    // Última escolha de áudio (fica em ~/.local/state/quickshell/...).
    FileView {
        id: audioFile
        path: Quickshell.statePath("record-audio")
        printErrors: false
        onLoaded: {
            const saved = text().trim();
            if (root.audioOptions.some(o => o.id === saved))
                root.audio = saved;
        }
    }

    // Se o Quickshell reiniciar no meio de uma gravação, retoma o indicador.
    Process {
        running: true
        command: ["bash", "-c", `${root.script} status`]
        onExited: code => {
            if (code === 0)
                root.recording = true;
        }
    }

    IpcHandler {
        target: "recording"

        function toggle(mode: string): void { root.toggle(mode); }
        function started(): void {
            root.startedAt = new Date();
            root.recording = true;
        }
        function stopped(): void { root.recording = false; }
    }
}
