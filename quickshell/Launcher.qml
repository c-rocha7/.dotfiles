pragma Singleton

// Estado do launcher (a busca que sai da ilha).
// - open:    launcher aberto
// - mode:    "apps" (apps, :emoji, =conta, >comando), "clipboard" (histórico) ou "windows" (janelas)
// - clips:   histórico do clipboard [{ id, text }], carregado ao abrir no modo clipboard
// - windows: janelas abertas [{ address, class, title, workspace }], carregadas ao abrir em "windows"
// - emojis:  lista de data/emojis.json [{ e, n (nome), k (palavras-chave) }]
//
// Atalhos do Hyprland:
//   qs ipc call launcher toggle      abre/fecha (apps)
//   qs ipc call launcher clipboard   abre direto no histórico do clipboard
//   qs ipc call launcher windows     abre na lista de janelas (SUPER+Tab)
//   qs ipc call launcher search ':'  abre já com um texto digitado (ex.: ':' emojis, '=' conta)

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

Singleton {
    id: root

    property bool open: false
    property string mode: "apps"
    property var clips: []
    property var windows: []
    property var emojis: []
    property string initialQuery: "" // texto já digitado ao abrir

    // Pasta onde as imagens do clipboard viram arquivos (para a prévia).
    readonly property string imageCache: Quickshell.cachePath("clipboard")

    function show(newMode, query) {
        mode = newMode;
        initialQuery = query ?? "";
        if (newMode === "clipboard")
            loadClips();
        if (newMode === "windows")
            windowList.running = true;
        QuickSettings.close();
        PowerMenu.close();
        Cheatsheet.close();
        Recorder.pickerOpen = false;
        Wallpaper.close();
        NotificationService.centerOpen = false;
        open = true;
    }

    function close() {
        open = false;
    }

    function loadClips() {
        clipList.running = true;
        // Prévias de imagens com mais de 7 dias são apagadas (são recriadas se precisar).
        Quickshell.execDetached(["find", imageCache, "-type", "f", "-mtime", "+7", "-delete"]);
    }

    // Copia um item do histórico de volta para a área de transferência.
    function copyClip(id) {
        Quickshell.execDetached(["bash", "-c", 'clipvault get "$1" | wl-copy', "_", String(id)]);
    }

    function deleteClip(id) {
        Quickshell.execDetached(["clipvault", "delete", String(id)]);
        clips = clips.filter(c => c.id !== id);
    }

    function copyText(text) {
        Quickshell.execDetached(["wl-copy", "--", text]);
    }

    function focusWindow(address) {
        Hyprland.dispatch(`hl.dsp.focus({ window = "address:${address}" })`);
    }

    // Saída do clipvault list: "id<TAB>prévia", um por linha, mais novo primeiro.
    Process {
        id: clipList
        command: ["clipvault", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.clips = text.split("\n").filter(l => l.includes("\t")).map(l => {
                    const tab = l.indexOf("\t");
                    return { id: l.slice(0, tab), text: l.slice(tab + 1) };
                });
            }
        }
    }

    // Janelas abertas (todas as workspaces), a mais usada recentemente primeiro.
    Process {
        id: windowList
        command: ["hyprctl", "clients", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.windows = JSON.parse(text)
                        .filter(c => c.mapped && c.title !== "")
                        .sort((a, b) => a.focusHistoryID - b.focusHistoryID)
                        .map(c => ({ address: c.address, class: c.class, title: c.title,
                                     workspace: c.workspace.name }));
                    // Como no SUPER+Tab: a janela atual vai pro fim, a anterior fica em primeiro.
                    if (root.windows.length > 1)
                        root.windows = [...root.windows.slice(1), root.windows[0]];
                } catch (e) {
                    root.windows = [];
                }
            }
        }
    }

    FileView {
        path: Quickshell.shellPath("data/emojis.json")
        onLoaded: root.emojis = JSON.parse(text())
    }

    IpcHandler {
        target: "launcher"

        function toggle(): void {
            if (root.open)
                root.close();
            else
                root.show("apps");
        }
        function clipboard(): void { root.show("clipboard"); }
        function windows(): void { root.show("windows"); }
        function search(text: string): void { root.show("apps", text); }
    }
}
