// Launcher que sai da ilha (substitui o rofi).
//
// Busca:
//   texto      apps (nome, descrição, palavras-chave) + ações dos apps + comandos de energia
//   =2+2*3     calculadora (Enter copia o resultado)
//   >comando   roda um comando no shell (Shift+Enter: roda dentro do terminal)
//   :nome      emojis (busca em português e inglês); Enter copia o emoji
// Modo clipboard (SUPER+V): histórico do clipvault (imagens com prévia); Enter copia, Delete apaga.
// Modo janelas (SUPER+Tab): janelas abertas, a mais recente primeiro; Enter vai até ela.
//
// Teclas: ↑/↓ ou Tab/Shift+Tab escolhem, Enter executa, Esc fecha.

import QtQuick
import Quickshell
import qs

IslandView {
    id: root

    readonly property int maxRows: 8
    readonly property int rowHeight: 40
    property string query: ""

    padH: 12
    padV: 12

    // Ao abrir: limpa a busca e foca o campo de texto.
    onShownChanged: {
        if (shown) {
            input.text = Launcher.initialQuery;
            query = input.text;
            list.currentIndex = 0;
            input.forceActiveFocus();
        }
    }

    // ---------- Resultados ----------

    // Cada resultado: { name, desc, icon (ícone do tema) ou glyph (ícone da fonte), run(shift) }
    readonly property var results: {
        if (Launcher.mode === "clipboard")
            return clipboardResults();
        if (Launcher.mode === "windows")
            return windowResults(query.trim().toLowerCase());
        const q = query.trim();
        if (q.startsWith(":"))
            return emojiResults(q.slice(1).trim().toLowerCase());
        if (q.startsWith("="))
            return calcResults(q.slice(1));
        if (q.startsWith(">"))
            return commandResults(q.slice(1).trim());
        return appResults(q.toLowerCase());
    }

    function close() {
        Launcher.close();
    }

    function runSelected(shift) {
        const item = results[list.currentIndex];
        if (!item)
            return;
        item.run(shift);
        close();
    }

    // Pontuação simples: começo do nome > começo de palavra > contém > outros campos.
    function score(q, name, extra) {
        const n = name.toLowerCase();
        if (n.startsWith(q))
            return 100;
        if (n.split(/[\s\-_.]+/).some(w => w.startsWith(q)))
            return 80;
        if (n.includes(q))
            return 60;
        if (extra.toLowerCase().includes(q))
            return 30;
        return 0;
    }

    function appResults(q) {
        const items = [];

        for (const entry of DesktopEntries.applications.values) {
            if (entry.noDisplay)
                continue;
            const extra = [entry.genericName, entry.comment, ...Array.from(entry.keywords ?? [])].join(" ");
            const s = q === "" ? 1 : score(q, entry.name, extra);
            if (s > 0)
                items.push({
                    score: s, name: entry.name,
                    desc: entry.genericName || entry.comment || "",
                    icon: entry.icon,
                    run: () => entry.execute()
                });

            // Ações do app (ex.: "Nova janela anônima"), só ao buscar.
            if (q === "")
                continue;
            for (const action of Array.from(entry.actions)) {
                const sa = score(q, `${entry.name} ${action.name}`, "");
                if (sa >= 60)
                    items.push({
                        score: sa - 5, name: action.name, desc: entry.name,
                        icon: action.icon || entry.icon,
                        run: () => action.execute()
                    });
            }
        }

        // Comandos de energia, só ao buscar.
        if (q !== "")
            for (const p of PowerMenu.actions) {
                const s = score(q, p.name, p.keywords);
                if (s > 0)
                    items.push({ score: s + 1, name: p.name, desc: p.desc, glyph: p.glyph,
                        run: () => PowerMenu.run(p) });
            }

        items.sort((a, b) => b.score - a.score || a.name.localeCompare(b.name, "pt-BR"));
        return items;
    }


    function calcResults(expr) {
        // Só aceita números e operadores (nada de código).
        const clean = expr.replace(/,/g, ".").replace(/\^/g, "**").trim();
        if (clean === "" || !/^[0-9+\-*/%(). ]+$/.test(clean))
            return [{ name: "Calculadora", desc: "Digite uma conta, ex.: =2+2*3", glyph: "", run: () => {} }];
        let value;
        try {
            value = Function(`"use strict"; return (${clean});`)();
        } catch (e) {
            return [{ name: "…", desc: "Conta incompleta", glyph: "", run: () => {} }];
        }
        if (typeof value !== "number" || !isFinite(value))
            return [{ name: "…", desc: "Resultado inválido", glyph: "", run: () => {} }];
        const result = String(Math.round(value * 1e10) / 1e10);
        return [{
            name: result, desc: "Enter copia o resultado", glyph: "",
            run: () => Quickshell.execDetached(["wl-copy", result])
        }];
    }

    function commandResults(cmd) {
        if (cmd === "")
            return [{ name: "Rodar comando", desc: "Digite um comando, ex.: >pavucontrol", glyph: "", run: () => {} }];
        return [{
            name: cmd, desc: "Enter roda · Shift+Enter roda no terminal", glyph: "",
            run: shift => Quickshell.execDetached(shift
                ? ["ghostty", "-e", "bash", "-c", `${cmd}; echo; read -n1 -p 'Pressione uma tecla para fechar...'`]
                : ["bash", "-c", cmd])
        }];
    }

    function clipboardResults() {
        const q = query.toLowerCase();
        return Launcher.clips
            .filter(c => q === "" || c.text.toLowerCase().includes(q))
            .map(c => {
                const image = c.text.startsWith("[[ binary") && c.text.includes("image/");
                return {
                    id: c.id, image: image,
                    name: image ? "Imagem" : c.text.replace(/\s+/g, " ").trim(),
                    desc: image ? c.text.replace(/^\[\[ binary data |\]\]$/g, "").trim() : "",
                    glyph: image ? "\uf03e" : "\uf0ea",
                    run: () => Launcher.copyClip(c.id)
                };
            });
    }

    // Emojis: todas as palavras digitadas precisam aparecer no nome ou nas palavras-chave.
    function emojiResults(q) {
        if (q === "")
            return Launcher.emojis.slice(0, 40).map(emojiItem);
        const words = q.split(/\s+/);
        const found = [];
        for (const e of Launcher.emojis) {
            const text = `${e.n} ${e.k}`.toLowerCase();
            if (words.every(w => text.includes(w)))
                found.push(e);
            if (found.length >= 60)
                break;
        }
        return found.map(emojiItem);
    }

    function emojiItem(e) {
        return { name: e.n, desc: "Enter copia", emoji: e.e, run: () => Launcher.copyText(e.e) };
    }

    // Janelas: busca no título e na classe (ex.: "zen", "ghostty").
    function windowResults(q) {
        return Launcher.windows
            .filter(w => q === "" || `${w.title} ${w.class}`.toLowerCase().includes(q))
            .map(w => {
                const entry = DesktopEntries.heuristicLookup(w.class);
                return {
                    name: w.title,
                    desc: `${entry?.name ?? w.class} · workspace ${w.workspace}`,
                    icon: entry?.icon || w.class,
                    run: () => Launcher.focusWindow(w.address)
                };
            });
    }

    // ---------- Interface ----------

    Column {
        width: 560
        spacing: 8

        // Campo de busca
        Rectangle {
            width: parent.width
            height: 42
            radius: 12
            color: Theme.base

            Row {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                spacing: 12

                BarText {
                    text: ({ clipboard: "\uf0ea", windows: "\uf2d2" })[Launcher.mode] ?? "\uf002"
                    color: Theme.blue
                }

                TextInput {
                    id: input
                    width: parent.width - 40
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.text
                    selectionColor: Theme.blue
                    selectedTextColor: Theme.base
                    font.family: Theme.font
                    font.pixelSize: 16
                    clip: true
                    onTextChanged: {
                        root.query = text;
                        list.currentIndex = 0;
                    }

                    // Texto de ajuda quando vazio
                    ThemedText {
                        visible: input.text === ""
                        anchors.verticalCenter: parent.verticalCenter
                        text: ({ clipboard: "Buscar no histórico…", windows: "Buscar janelas…" })[Launcher.mode]
                              ?? "Buscar apps  ·  =conta  ·  >comando  ·  :emoji"
                        color: Theme.overlay
                        font.pixelSize: 16
                        font.weight: Font.Normal
                    }

                    Keys.onPressed: event => {
                        const n = root.results.length;
                        if (event.key === Qt.Key_Escape) {
                            root.close();
                        } else if (event.key === Qt.Key_Down || (event.key === Qt.Key_Tab && n > 0)) {
                            list.currentIndex = (list.currentIndex + 1) % Math.max(1, n);
                        } else if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab) {
                            list.currentIndex = (list.currentIndex - 1 + n) % Math.max(1, n);
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            root.runSelected(event.modifiers & Qt.ShiftModifier);
                        } else if (event.key === Qt.Key_Delete && Launcher.mode === "clipboard") {
                            const item = root.results[list.currentIndex];
                            if (item)
                                Launcher.deleteClip(item.id);
                        } else {
                            return;
                        }
                        event.accepted = true;
                    }
                }
            }
        }

        // Lista de resultados
        ListView {
            id: list
            width: parent.width
            height: Math.min(count, root.maxRows) * root.rowHeight
            visible: count > 0
            clip: true
            model: root.results
            boundsBehavior: Flickable.StopAtBounds
            highlightMoveDuration: 80

            highlight: Rectangle {
                radius: 10
                color: Theme.surface1
            }

            delegate: LauncherItem {
                required property var modelData
                required property int index

                width: list.width
                height: root.rowHeight
                item: modelData
                selected: ListView.isCurrentItem

                onHovered: list.currentIndex = index
                onClicked: {
                    list.currentIndex = index;
                    root.runSelected(false);
                }
            }
        }

        // Prévia da imagem selecionada (histórico do clipboard)
        Rectangle {
            readonly property var item: root.results[list.currentIndex]
            visible: Launcher.mode === "clipboard" && !!item?.image
            width: parent.width
            height: 200
            radius: 12
            color: Theme.base

            ClipImage {
                anchors.fill: parent
                anchors.margins: 8
                clipId: parent.visible ? parent.item.id : ""
                clipText: parent.visible ? parent.item.desc : ""
            }
        }

        ThemedText {
            visible: list.count === 0
            width: parent.width
            topPadding: 6
            bottomPadding: 6
            horizontalAlignment: Text.AlignHCenter
            text: Launcher.mode === "clipboard" ? "Histórico vazio"
                : Launcher.mode === "windows" ? "Nenhuma janela" : "Nada encontrado"
            color: Theme.overlay
            font.weight: Font.Normal
        }
    }
}
