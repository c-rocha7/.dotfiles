// Moldura de um monitor: uma janela do tamanho da tela, por cima das janelas, que só recebe
// cliques na barra, nas bordas e nos painéis abertos (o "mask"); o miolo passa para as janelas.
//
// Barra:   workspaces (esquerda) · data e hora (centro, abre o calendário) · status (direita)
// Painéis (FramePanel, brotam da moldura; reaproveitam as telas de qs.bar):
//   topo, centro ......... launcher, gravação, wallpapers, atalhos, energia, calendário + clima + mídia
//   canto direito ........ central de notificações, central de controle (Wi-Fi, Bluetooth, áudio, bateria), notificação nova
//   borda direita ........ volume, brilho e avisos rápidos (microfone, Caps Lock, GameMode)
// Clique fora ou Esc fecha. O teclado só é pego com um painel aberto.

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import Quickshell.Services.Notifications
import Quickshell.Services.Pipewire
import Quickshell.Wayland
import qs
import qs.bar

PanelWindow {
    id: win

    required property var modelData
    screen: modelData

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore      // o espaço é reservado pelas janelas Exclusion
    WlrLayershell.namespace: "moldura"
    WlrLayershell.layer: WlrLayer.Top

    // Um menu da bandeja está aberto (usado pela bandeja).
    property bool menuOpen: false

    // ---------- Estado dos painéis ----------

    readonly property bool focusedScreen: Hyprland.focusedMonitor?.name === screen?.name
    readonly property bool calendarOpen: CalendarPanel.open

    // Painel do topo (um por vez; mesma prioridade da ilha)
    readonly property string topPanel: !focusedScreen ? ""
        : Launcher.open ? "launcher"
        : Recorder.pickerOpen ? "record"
        : Wallpaper.open ? "wallpaper"
        : Cheatsheet.open ? "keys"
        : PowerMenu.open ? "power"
        : calendarOpen ? "calendar"
        : ""
    // Painel do canto direito
    readonly property string sidePanel: NotificationService.centerOpen ? "center"
        : focusedScreen && (ControlCenter.open || QuickSettings.open || Audio.open) ? "control"
        : ""
    // Página da central: a pedida, ou Wi-Fi/Bluetooth/áudio abertos por atalho/IPC
    readonly property string controlPage: ControlCenter.open ? ControlCenter.page
        : QuickSettings.open ? QuickSettings.tab
        : "audio"
    readonly property bool anyPanel: topPanel !== "" || sidePanel !== ""

    function closeAll() {
        Launcher.close();
        NotificationService.centerOpen = false;
        QuickSettings.close();
        PowerMenu.close();
        Cheatsheet.close();
        Recorder.pickerOpen = false;
        Wallpaper.close();
        Audio.close();
        ControlCenter.close();
        CalendarPanel.open = false;
    }

    WlrLayershell.keyboardFocus: anyPanel ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    // Clique fora da moldura/painéis fecha (o Hyprland avisa via "focus grab").
    HyprlandFocusGrab {
        windows: [win]
        active: win.anyPanel
        onCleared: win.closeAll()
    }

    // Esc fecha (os painéis com campo de texto tratam o Esc deles).
    Item {
        focus: true
        Keys.onEscapePressed: win.closeAll()
    }

    // ---------- Avisos rápidos (OSD) ----------

    property string osd: ""   // "volume" | "brightness" | "toast" | "notification" | ""
    readonly property MprisPlayer player: {
        const players = Mpris.players.values;
        return players.find(p => p.isPlaying) ?? players[0] ?? null;
    }

    function showOsd(kind, ms) {
        osd = kind;
        osdTimer.interval = ms;
        osdTimer.restart();
    }
    function showToast(icon, text, accent) {
        toastView.icon = icon;
        toastView.text = text;
        toastView.accent = accent;
        showOsd("toast", 1500);
    }

    Timer {
        id: osdTimer
        onTriggered: win.osd = ""
    }

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource
    PwObjectTracker {
        objects: [win.sink, win.source]
    }
    Connections {
        target: win.sink?.audio ?? null
        function onVolumeChanged() { win.showOsd("volume", 2000); }
        function onMutedChanged() { win.showOsd("volume", 2000); }
    }
    Connections {
        target: win.source?.audio ?? null
        function onMutedChanged() {
            const muted = win.source.audio.muted;
            win.showToast(muted ? "" : "", muted ? "Microfone mudo" : "Microfone ligado",
                          muted ? Theme.red : Theme.green);
        }
    }
    Connections {
        target: Keyboard
        function onCapsUpdated() {
            win.showToast("\u{f0632}", Keyboard.capsLock ? "Caps Lock ligado" : "Caps Lock desligado",
                          Keyboard.capsLock ? Theme.blue : Theme.overlay);
        }
    }
    Connections {
        target: GameMode
        function onToggled() {
            win.showToast("\u{f0297}", GameMode.active ? "GameMode ativo · Desempenho" : "GameMode desligado",
                          GameMode.active ? Theme.green : Theme.overlay);
        }
    }
    Connections {
        target: Brightness
        function onUpdated() { if (win.sidePanel !== "control") win.showOsd("brightness", 2000); }
    }
    Connections {
        target: NotificationService
        function onReceived(n) {
            notificationView.notification = n;
            const critical = n.urgency === NotificationUrgency.Critical;
            win.showOsd("notification", n.expireTimeout > 0 ? n.expireTimeout : critical ? 10000 : 5000);
        }
    }

    // ---------- Cliques: barra, bordas e painéis abertos ----------

    mask: Region {
        Region { item: topStrip }
        Region { item: leftStrip }
        Region { item: rightStrip }
        Region { item: bottomStrip }
        Region { item: launcherPanel }
        Region { item: recordPanel }
        Region { item: wallpaperPanel }
        Region { item: keysPanel }
        Region { item: powerPanel }
        Region { item: calendarPanel }
        Region { item: centerPanel }
        Region { item: controlPanel }
        Region { item: notificationPanel }
        Region { item: osdPanel }
    }

    // Camada de fundo: moldura + fundos dos painéis, translúcida por inteiro (Theme.frameOpacity).
    Item {
        id: background
        anchors.fill: parent
        opacity: Theme.frameOpacity
        layer.enabled: Theme.frameOpacity < 1

        FrameShape {
            anchors.fill: parent
        }
    }

    Item { id: topStrip; anchors { top: parent.top; left: parent.left; right: parent.right } height: Theme.frameBar }
    Item { id: leftStrip; anchors { top: parent.top; bottom: parent.bottom; left: parent.left } width: Theme.frameBorder }
    Item { id: rightStrip; anchors { top: parent.top; bottom: parent.bottom; right: parent.right } width: Theme.frameBorder }
    Item { id: bottomStrip; anchors { bottom: parent.bottom; left: parent.left; right: parent.right } height: Theme.frameBorder }

    // ---------- Barra ----------

    readonly property real barItemY: (Theme.frameBar - Theme.barHeight) / 2

    // Esquerda: energia + workspaces
    Row {
        anchors.left: parent.left
        anchors.leftMargin: Theme.frameBorder + 4
        y: win.barItemY
        spacing: 6
        PowerButton {}
        FrameWorkspaces {}
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // Centro: data e hora (clique: calendário e mídia)
    Pill {
        anchors.horizontalCenter: parent.horizontalCenter
        y: win.barItemY
        clickable: true
        color: win.calendarOpen ? Theme.surface1 : hovered ? Theme.surface1 : "transparent"

        BarText {
            visible: win.player?.isPlaying ?? false
            text: ""
            color: Theme.green
        }
        BarText {
            text: Qt.locale().toString(clock.date, "ddd d MMM")
            color: Theme.subtext
        }
        BarText {
            text: Qt.formatDateTime(clock.date, "HH:mm")
            font.bold: true
        }

        onClicked: {
            const was = win.calendarOpen;
            win.closeAll();
            CalendarPanel.open = !was;
        }
    }

    // Direita: status
    Row {
        anchors.right: parent.right
        anchors.rightMargin: Theme.frameBorder + 4
        y: win.barItemY
        spacing: Theme.gap

        BarText {
            visible: Keyboard.capsLock
            anchors.verticalCenter: parent.verticalCenter
            text: "\u{f0632}"
            color: Theme.blue
        }
        UpdatesPill {}
        RecordPill {}
        Tray { bar: win }
        // GitHub: só aparece com notificações ou revisões pendentes
        Pill {
            visible: GitHub.pending > 0
            clickable: true
            color: hovered ? Theme.surface1 : Theme.base
            BarText { text: "\u{f02a4}"; color: Theme.blue }
            BarText { text: GitHub.pending }
            onClicked: ControlCenter.toggle("github")
        }
        // Wi-Fi, Bluetooth e volume: só os ícones; os controles ficam na central
        StatusCluster { open: win.sidePanel === "control" }
        BatteryPill {}
        Notifications {}
    }

    // ---------- Painéis do topo (centro) ----------


    FramePanel {
        background: background
        attach: "top"
        x: Math.round((win.width - fullWidth) / 2)
        y: Theme.frameBar
        id: launcherPanel
        shown: win.topPanel === "launcher"
        body: launcherView
        LauncherView { id: launcherView; shown: launcherPanel.shown }
    }
    FramePanel {
        background: background
        attach: "top"
        x: Math.round((win.width - fullWidth) / 2)
        y: Theme.frameBar
        id: recordPanel
        shown: win.topPanel === "record"
        body: recordView
        RecordPickerView { id: recordView; shown: recordPanel.shown }
    }
    FramePanel {
        background: background
        attach: "top"
        x: Math.round((win.width - fullWidth) / 2)
        y: Theme.frameBar
        id: wallpaperPanel
        shown: win.topPanel === "wallpaper"
        body: wallpaperView
        WallpaperView { id: wallpaperView; shown: wallpaperPanel.shown }
    }
    FramePanel {
        background: background
        attach: "top"
        x: Math.round((win.width - fullWidth) / 2)
        y: Theme.frameBar
        id: keysPanel
        shown: win.topPanel === "keys"
        body: keysView
        CheatsheetView { id: keysView; shown: keysPanel.shown }
    }
    FramePanel {
        background: background
        attach: "top"
        x: Math.round((win.width - fullWidth) / 2)
        y: Theme.frameBar
        id: powerPanel
        shown: win.topPanel === "power"
        body: powerView
        PowerView { id: powerView; shown: powerPanel.shown }
    }
    FramePanel {
        background: background
        attach: "top"
        x: Math.round((win.width - fullWidth) / 2)
        y: Theme.frameBar
        id: calendarPanel
        shown: win.topPanel === "calendar"
        body: calendarView
        IslandView {
            id: calendarView
            shown: calendarPanel.shown
            padH: 6
            padV: 6
            onShownChanged: if (!shown) {
                calendar.offset = 0;
                calendar.selectedDate = new Date();     // ao abrir de novo: hoje
            }

            // Calendário à esquerda; clima e mídia à direita
            Row {
                spacing: 12

                // Calendário (clicar num dia mostra os eventos dele na agenda ao lado)
                Calendar {
                    id: calendar
                    date: clock.date
                    cell: 38
                    rowHeight: 28
                    dayFont: 13
                    eventDays: Agenda.days
                    selectable: true
                }
                Column {
                    spacing: 10
                    WeatherCard {}
                    AgendaCard {
                        width: 320
                        now: clock.date
                        day: calendar.selectedDate
                    }
                    MediaCard {}
                }
            }
        }
    }

    // ---------- Painéis do canto direito ----------


    FramePanel {
        background: background
        attach: "topRight"
        x: win.width - Theme.frameBorder - fullWidth
        y: Theme.frameBar
        id: centerPanel
        shown: win.sidePanel === "center"
        body: centerView
        NotificationCenter { id: centerView; shown: centerPanel.shown }
    }
    FramePanel {
        background: background
        id: controlPanel
        attach: "topRight"
        x: win.width - Theme.frameBorder - fullWidth
        y: Theme.frameBar
        shown: win.sidePanel === "control"
        body: controlView
        ControlCenterView {
            id: controlView
            shown: controlPanel.shown
            page: win.controlPage
            player: win.player
        }
    }
    // Notificação nova (some sozinha; com o mouse em cima, espera)
    FramePanel {
        background: background
        attach: "topRight"
        x: win.width - Theme.frameBorder - fullWidth
        y: Theme.frameBar
        id: notificationPanel
        shown: win.sidePanel === "" && win.osd === "notification" && notificationView.notification !== null
        body: notificationView
        NotificationView {
            id: notificationView
            shown: notificationPanel.shown
            onHide: win.osd = ""
        }
        HoverHandler {
            onHoveredChanged: hovered ? osdTimer.stop() : osdTimer.restart()
        }
    }

    // ---------- Borda direita: volume, brilho, avisos ----------

    FramePanel {
        background: background
        id: osdPanel
        attach: "right"
        shown: win.osd === "volume" || win.osd === "brightness" || win.osd === "toast"
        x: win.width - Theme.frameBorder - width
        y: Math.round((win.height - fullHeight) / 2)
        body: win.osd === "brightness" ? brightnessView : win.osd === "toast" ? toastView : volumeView

        VerticalLevel {
            id: volumeView
            shown: win.osd === "volume"
            readonly property real vol: win.sink?.audio?.volume ?? 0
            value: vol
            dim: win.sink?.audio?.muted ?? false
            icon: dim ? "\u{f075f}" : vol < 0.34 ? "\uf026" : vol < 0.67 ? "\uf027" : "\uf028"
        }
        VerticalLevel {
            id: brightnessView
            shown: win.osd === "brightness"
            value: Brightness.value
            icon: "\u{f00df}"
        }
        ToastView { id: toastView; shown: win.osd === "toast" }
    }
}
