// Visão geral das workspaces: todas lado a lado (3 + 2), com miniaturas ao vivo das janelas.
//   Clique numa janela ......... vai até ela
//   Clique no fundo de um card . vai para a workspace
//   Arrastar uma janela ........ move para outra workspace (sem trocar de tela)
//   Clique do meio na janela ... fecha a janela
//   Esc / clique fora / 1-5 .... fecha / vai para a workspace N
//   Digitar .................... busca janelas (título ou app); setas/Tab escolhem, Enter vai
// Uma janela por monitor (mostra as workspaces daquele monitor). Aberta por Overview.open.

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs
import qs.bar

PanelWindow {
    id: win

    required property var modelData
    screen: modelData

    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(modelData)
    readonly property real monScale: monitor?.scale ?? 1
    readonly property real monX: monitor?.x ?? 0
    readonly property real monY: monitor?.y ?? 0
    readonly property real monW: (monitor?.width ?? 1920) / monScale
    readonly property real monH: (monitor?.height ?? 1080) / monScale

    // Workspaces mostradas: 1 a 5 e qualquer outra (>5) que exista neste monitor
    readonly property var workspaces: {
        const ids = [1, 2, 3, 4, 5];
        for (const w of Hyprland.workspaces.values)
            if (w.id > 5 && w.monitor === monitor && !ids.includes(w.id))
                ids.push(w.id);
        return ids.sort((a, b) => a - b);
    }
    readonly property int columns: 3
    readonly property real gap: 28
    // Tamanho do card (a janela começa com 0x0: sem o mínimo, as capturas nascem com tamanho negativo e falham)
    readonly property real cardW: Math.max(120, Math.min((width - 160 - (columns - 1) * gap) / columns,
                                           (height - 200) / Math.ceil(workspaces.length / columns) * monW / monH - 40))
    readonly property real cardH: cardW * monH / monW
    readonly property real s: cardW / monW      // escala tela → card

    // Busca: digitar filtra as janelas; "sel" é a escolhida entre as que combinam
    readonly property string query: Overview.query
    property int sel: 0
    readonly property var matches: {
        const q = query.trim().toLowerCase();
        if (q === "")
            return [];
        return Hyprland.toplevels.values
            .filter(t => workspaces.includes(t.workspace?.id) && t.lastIpcObject?.at)
            .filter(t => [t.lastIpcObject.title, t.lastIpcObject.class, t.wayland?.appId]
                .some(x => (x || "").toLowerCase().includes(q)))
            .sort((a, b) => a.workspace.id - b.workspace.id);
    }
    readonly property var selected: matches.length ? matches[Math.min(sel, matches.length - 1)] : null
    onQueryChanged: sel = 0

    // Arraste em andamento
    property var dragging: null                 // HyprlandToplevel
    property real dragX: 0
    property real dragY: 0
    property int dropTarget: -1
    property var cards: []

    color: "transparent"
    visible: Overview.open || content.opacity > 0
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "overview"
    WlrLayershell.keyboardFocus: Overview.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    function dispatch(cmd) {
        Hyprland.dispatch(cmd);
        refreshLater.restart();
    }
    function goWorkspace(id) {
        Hyprland.dispatch(`hl.dsp.focus({ workspace = ${id} })`);
        Overview.close();
    }
    function goWindow(t) {
        Hyprland.dispatch(`hl.dsp.focus({ window = "address:0x${t.address}" })`);
        Overview.close();
    }
    function cardAt(x, y) {
        for (const c of cards) {
            const p = c.mapFromItem(content, x, y);
            if (p.x >= 0 && p.y >= 0 && p.x <= c.width && p.y <= c.height)
                return c.wsId;
        }
        return -1;
    }

    Connections {
        target: Overview
        function onOpenChanged() {
            if (Overview.open) {
                Hyprland.refreshToplevels();
                Hyprland.refreshWorkspaces();
                Hyprland.refreshMonitors();
                Wallpaper.readCurrent();
                Overview.query = "";
                content.forceActiveFocus();
            } else {
                win.dragging = null;
            }
        }
    }
    Timer {
        id: refreshLater
        interval: 150
        onTriggered: Hyprland.refreshToplevels()
    }

    Item {
        id: content
        anchors.fill: parent
        focus: true
        opacity: Overview.open ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

        Keys.onPressed: event => {
            const n = win.matches.length;
            if (event.key === Qt.Key_Escape) {
                if (win.query !== "") Overview.query = "";
                else Overview.close();
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                if (win.selected) win.goWindow(win.selected);
                else Overview.close();
            } else if (event.key === Qt.Key_Backspace) {
                Overview.query = win.query.slice(0, -1);
            } else if (n && (event.key === Qt.Key_Right || event.key === Qt.Key_Down || event.key === Qt.Key_Tab)) {
                win.sel = (Math.min(win.sel, n - 1) + 1) % n;
            } else if (n && (event.key === Qt.Key_Left || event.key === Qt.Key_Up || event.key === Qt.Key_Backtab)) {
                win.sel = (Math.min(win.sel, n - 1) - 1 + n) % n;
            } else if (win.query === "" && event.key >= Qt.Key_1 && event.key <= Qt.Key_9) {
                win.goWorkspace(event.key - Qt.Key_0);
            } else if (event.text.length === 1 && event.text >= " " && !(event.modifiers & Qt.ControlModifier)) {
                Overview.query += event.text;
            } else {
                return;
            }
            event.accepted = true;
        }

        // Fundo escurecido (o Hyprland desfoca por trás: layer_rule "overview")
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0.07, 0.07, 0.11, 0.72)
            MouseArea {
                anchors.fill: parent
                onClicked: Overview.close()
            }
        }

        Column {
            id: grid
            anchors.centerIn: parent
            spacing: win.gap
            scale: Overview.open ? 1 : 0.94
            Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

            Repeater {
                // linhas de 3
                model: Math.ceil(win.workspaces.length / win.columns)

                Row {
                    required property int index
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: win.gap

                    Repeater {
                        model: win.workspaces.slice(index * win.columns, (index + 1) * win.columns)

                        Column {
                            id: cardCol
                            required property int modelData
                            spacing: 8

                            // Card da workspace
                            Rectangle {
                                id: card
                                readonly property int wsId: cardCol.modelData
                                readonly property bool active: win.monitor?.activeWorkspace?.id === wsId
                                readonly property var windows: Hyprland.toplevels.values
                                    .filter(t => t.workspace?.id === wsId && t.lastIpcObject?.at)
                                    .sort((a, b) => (a.lastIpcObject.floating ? 1 : 0) - (b.lastIpcObject.floating ? 1 : 0))

                                width: win.cardW
                                height: win.cardH
                                radius: 12
                                color: Theme.base
                                clip: true
                                border.width: 2
                                border.color: win.dropTarget === wsId ? Theme.green
                                    : active ? Theme.blue
                                    : cardMouse.containsMouse ? Theme.overlay : Theme.surface1

                                Component.onCompleted: win.cards = win.cards.concat([card])
                                Component.onDestruction: win.cards = win.cards.filter(c => c !== card)

                                Image {
                                    anchors.fill: parent
                                    anchors.margins: 2
                                    source: Wallpaper.current ? "file://" + Wallpaper.current : ""
                                    fillMode: Image.PreserveAspectCrop
                                    sourceSize: Qt.size(win.cardW, win.cardH)
                                    asynchronous: true
                                    opacity: 0.55
                                }

                                MouseArea {
                                    id: cardMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: win.goWorkspace(card.wsId)
                                }

                                Repeater {
                                    model: card.windows

                                    Item {
                                        id: thumb
                                        required property var modelData
                                        readonly property var ipc: modelData.lastIpcObject
                                        readonly property string appId: modelData.wayland?.appId || ipc?.class || ""

                                        x: (ipc.at[0] - win.monX) * win.s
                                        y: (ipc.at[1] - win.monY) * win.s
                                        width: ipc.size[0] * win.s
                                        height: ipc.size[1] * win.s
                                        readonly property bool dimmed: win.query !== "" && !win.matches.includes(modelData)
                                        readonly property bool chosen: win.selected === modelData
                                        opacity: win.dragging === modelData ? 0.3 : dimmed ? 0.2 : 1
                                        z: chosen ? 1 : 0
                                        Behavior on opacity { NumberAnimation { duration: 120 } }

                                        Rectangle {
                                            anchors.fill: parent
                                            radius: 6
                                            color: Theme.surface0
                                            border.width: winMouse.containsMouse || thumb.chosen ? 2 : 0
                                            border.color: thumb.chosen ? Theme.green : Theme.blue
                                            clip: true

                                            ScreencopyView {
                                                anchors.fill: parent
                                                anchors.margins: winMouse.containsMouse || thumb.chosen ? 2 : 0
                                                captureSource: Overview.open && thumb.width > 4 && thumb.height > 4 ? thumb.modelData.wayland : null
                                                live: Overview.open
                                            }
                                        }
                                        Image {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            anchors.bottom: parent.bottom
                                            anchors.bottomMargin: 6
                                            width: Math.min(32, parent.width / 3)
                                            height: width
                                            sourceSize: Qt.size(64, 64)
                                            source: Quickshell.iconPath(DesktopEntries.heuristicLookup(thumb.appId)?.icon ?? thumb.appId, "application-x-executable")
                                        }

                                        MouseArea {
                                            id: winMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                                            cursorShape: win.dragging ? Qt.ClosedHandCursor : Qt.PointingHandCursor
                                            property point start

                                            onPressed: mouse => start = Qt.point(mouse.x, mouse.y)
                                            onPositionChanged: mouse => {
                                                if (!(mouse.buttons & Qt.LeftButton)) return;
                                                if (!win.dragging && Math.hypot(mouse.x - start.x, mouse.y - start.y) < 8) return;
                                                win.dragging = thumb.modelData;
                                                const p = mapToItem(content, mouse.x, mouse.y);
                                                win.dragX = p.x;
                                                win.dragY = p.y;
                                                win.dropTarget = win.cardAt(p.x, p.y);
                                            }
                                            onReleased: mouse => {
                                                if (!win.dragging) return;
                                                const target = win.dropTarget;
                                                const t = win.dragging;
                                                win.dragging = null;
                                                win.dropTarget = -1;
                                                if (target > 0 && target !== card.wsId)
                                                    win.dispatch(`hl.dsp.window.move({ workspace = ${target}, follow = false, window = "address:0x${t.address}" })`);
                                            }
                                            onClicked: mouse => {
                                                if (win.dragging) return;
                                                if (mouse.button === Qt.MiddleButton)
                                                    win.dispatch(`hl.dsp.window.close({ window = "address:0x${thumb.modelData.address}" })`);
                                                else
                                                    win.goWindow(thumb.modelData);
                                            }
                                        }
                                    }
                                }
                            }

                            // Número da workspace
                            ThemedText {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: card.windows.length ? `${card.wsId}  ·  ${card.windows.length} ${card.windows.length === 1 ? "janela" : "janelas"}` : `${card.wsId}`
                                font.bold: card.active
                                color: card.active ? Theme.blue : Theme.subtext
                            }
                        }
                    }
                }
            }
        }

        // Janela sendo arrastada (segue o mouse)
        Rectangle {
            visible: win.dragging !== null
            width: 160
            height: 100
            x: win.dragX - width / 2
            y: win.dragY - height / 2
            radius: 8
            color: Theme.surface0
            border.width: 2
            border.color: Theme.green
            clip: true
            ScreencopyView {
                anchors.fill: parent
                anchors.margins: 2
                captureSource: win.dragging?.wayland ?? null
                live: true
            }
        }

        // Campo de busca (em cima)
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 60
            width: Math.max(360, searchRow.implicitWidth + 32)
            height: 40
            radius: 20
            color: Theme.base
            border.width: 1
            border.color: win.query !== "" ? Theme.blue : Theme.surface1

            Row {
                id: searchRow
                anchors.centerIn: parent
                spacing: 10
                BarText { text: "\uf002"; color: Theme.subtext }
                ThemedText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: win.query !== "" ? win.query : "Digite para buscar janelas"
                    color: win.query !== "" ? Theme.text : Theme.overlay
                }
                ThemedText {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: win.query !== ""
                    text: win.matches.length === 0 ? "nenhuma" : win.matches.length === 1 ? "1 janela" : `${win.matches.length} janelas`
                    font.pixelSize: 11
                    color: win.matches.length ? Theme.green : Theme.red
                }
            }
        }

        ThemedText {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 40
            text: win.query !== ""
                ? "Setas/Tab: escolher  ·  Enter: ir  ·  Esc: limpar a busca"
                : "Digite: buscar  ·  Clique: ir  ·  Arrastar: mover  ·  Clique do meio: fechar  ·  1-5  ·  Esc"
            font.pixelSize: 12
            color: Theme.overlay
        }
    }
}
