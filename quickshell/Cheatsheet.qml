pragma Singleton

// Guia de atalhos (SUPER + /).
// Lê os atalhos direto do Hyprland (`hyprctl binds -j`): aparecem os que têm
// `description = "Categoria · O que faz"` no hyprland.lua. Atalho novo com descrição
// entra no guia sozinho.
//
//   qs ipc call keys toggle   abre/fecha o guia

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool open: false

    // [{ category, items: [{ keys, text }] }], na ordem em que aparecem no hyprland.lua
    property var groups: []

    function show() {
        Launcher.close();
        PowerMenu.close();
        QuickSettings.close();
        Recorder.pickerOpen = false;
        Wallpaper.close();
        NotificationService.centerOpen = false;
        reader.running = true;
        open = true;
    }

    function close() {
        open = false;
    }

    // Nomes amigáveis para teclas e modificadores.
    readonly property var keyNames: ({
            "Space": "Espaço", "Tab": "Tab", "Escape": "Esc", "PRINT": "Print", "Print": "Print",
            "left": "←", "right": "→", "up": "↑", "down": "↓", "equal": "=", "minus": "-", "slash": "/",
            "mouse_down": "Rolar ↓", "mouse_up": "Rolar ↑", "mouse:272": "Clique esq.", "mouse:273": "Clique dir.",
            "XF86AudioRaiseVolume": "Volume +", "XF86AudioLowerVolume": "Volume −",
            "XF86AudioMute": "Mudo", "XF86AudioMicMute": "Mic mudo",
            "XF86MonBrightnessUp": "Brilho +", "XF86MonBrightnessDown": "Brilho −",
            "XF86AudioNext": "Próxima", "XF86AudioPrev": "Anterior",
            "XF86AudioPlay": "Play", "XF86AudioPause": "Pause"
        })

    function keyText(modmask, key) {
        const mods = [];
        if (modmask & 64) mods.push("SUPER");
        if (modmask & 4) mods.push("CTRL");
        if (modmask & 8) mods.push("ALT");
        if (modmask & 1) mods.push("SHIFT");
        mods.push(keyNames[key] ?? key.toUpperCase());
        return mods.join(" + ");
    }

    Process {
        id: reader
        command: ["hyprctl", "binds", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                let binds;
                try {
                    binds = JSON.parse(text);
                } catch (e) {
                    return;
                }
                const groups = [];
                const seen = new Set();
                for (const b of binds) {
                    if (!b.has_description)
                        continue;
                    const sep = b.description.indexOf(" · ");
                    const category = sep >= 0 ? b.description.slice(0, sep) : "Outros";
                    const label = sep >= 0 ? b.description.slice(sep + 3) : b.description;
                    const keys = root.keyText(b.modmask, b.key);
                    if (seen.has(keys + label))
                        continue;
                    seen.add(keys + label);
                    let group = groups.find(g => g.category === category);
                    if (!group) {
                        group = { category: category, items: [] };
                        groups.push(group);
                    }
                    // Teclas sem modificador com a mesma função viram uma linha (ex.: Play / Pause).
                    const twin = group.items.find(i => i.text === label && !i.keys.includes(" + ") && !keys.includes(" + "));
                    if (twin)
                        twin.keys += " / " + keys;
                    else
                        group.items.push({ keys: keys, text: label });
                }
                root.groups = groups;
            }
        }
    }

    IpcHandler {
        target: "keys"

        function toggle(): void {
            if (root.open)
                root.close();
            else
                root.show();
        }
    }
}
