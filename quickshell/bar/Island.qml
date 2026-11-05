// A ilha dinâmica. Mostra uma "tela" por vez, nesta ordem de prioridade:
//   0. launcher / power (menu de energia) / keys (guia de atalhos) / record (áudio da gravação)
//      wallpaper (troca de wallpaper)
//      launcher     – busca de apps / clipboard / calculadora (SUPER+Space, SUPER+V)
//   1. center       – painel de notificações (aberto pelo sino)
//   1b. connections – painel Wi-Fi/Bluetooth (blocos de Wi-Fi/Bluetooth)
//   2. hover        – mouse em cima (ou menu da bandeja aberto): workspaces, mídia, controles e calendário
//   3. volume       – por 2s quando o volume muda (brightness: idem para o brilho)
//      toast        – 1,5s: microfone mudo/ligado, Caps Lock ligado/desligado
//   4. notification – quando chega uma notificação (5s, ou o tempo pedido pelo app)
//   5. media        – enquanto alguma mídia estiver tocando
//   6. compact      – workspace atual e hora
// A ilha anima o tamanho para caber a tela atual.

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import Quickshell.Services.Notifications
import Quickshell.Services.Pipewire
import qs

Rectangle {
    id: island

    // Janela da barra (usada pelos menus da bandeja).
    required property var window

    // ---------- Estado ----------

    property bool hovered: false
    property string osd: "" // "volume", "notification" ou ""

    // Player de mídia: o que estiver tocando, senão o primeiro aberto.
    readonly property MprisPlayer player: {
        const players = Mpris.players.values;
        return players.find(p => p.isPlaying) ?? players[0] ?? null;
    }

    // Launcher e painel de notificações abrem só no monitor em foco.
    readonly property bool focusedScreen: Hyprland.focusedMonitor?.name === window.screen?.name
    readonly property bool launcherOpen: Launcher.open && focusedScreen
    readonly property bool wallpaperOpen: Wallpaper.open && focusedScreen
    readonly property bool recordOpen: Recorder.pickerOpen && focusedScreen
    readonly property bool keysOpen: Cheatsheet.open && focusedScreen
    readonly property bool powerOpen: PowerMenu.open && focusedScreen
    readonly property bool connectionsOpen: QuickSettings.open && focusedScreen
    readonly property bool centerOpen: NotificationService.centerOpen
        && Hyprland.focusedMonitor?.name === window.screen?.name

    // Some com o aviso se a notificação for dispensada enquanto aparece.
    readonly property bool osdValid: osd !== "" && (osd !== "notification" || notificationView.notification !== null)

    readonly property string mode: launcherOpen ? "launcher"
        : recordOpen ? "record"
        : wallpaperOpen ? "wallpaper"
        : keysOpen ? "keys"
        : powerOpen ? "power"
        : centerOpen ? "center"
        : connectionsOpen ? "connections"
        // Mouse em cima de uma notificação: ela continua na tela (para dar para clicar).
        : (hovered && !(osdValid && osd === "notification")) || window.menuOpen ? "hover"
        : osdValid ? osd
        : player?.isPlaying && !Recorder.recording ? "media" // gravando: a ilha fechada mostra o tempo
        : "compact"

    readonly property Item activeView: ({
            launcher: launcherView,
            power: powerView,
            keys: keysView,
            record: recordView,
            wallpaper: wallpaperView,
            center: centerView,
            connections: connectionsView,
            hover: hoverView,
            volume: volumeView,
            brightness: brightnessView,
            toast: toastView,
            notification: notificationView,
            media: mediaView,
            compact: compactView
        })[mode]

    // Aviso curto (ícone + texto).
    function showToast(icon, text, accent) {
        toastView.icon = icon;
        toastView.text = text;
        toastView.accent = accent;
        showOsd("toast", 1500);
    }

    function showOsd(kind, ms) {
        osd = kind;
        osdTimer.interval = ms;
        osdTimer.restart();
    }

    // ---------- Aparência e animação ----------

    width: activeView.implicitWidth
    height: activeView.implicitHeight
    radius: Math.min(height / 2, 24)
    color: Theme.island
    clip: true

    Behavior on width {
        NumberAnimation {
            duration: Theme.resizeDuration
            easing.type: Easing.OutBack
            easing.overshoot: 1.1
        }
    }
    Behavior on height {
        NumberAnimation {
            duration: Theme.resizeDuration
            easing.type: Easing.OutBack
            easing.overshoot: 1.1
        }
    }

    // ---------- Gatilhos ----------

    // Hover: abre após 150ms (evita abrir sem querer), fecha 300ms após sair.
    HoverHandler {
        onHoveredChanged: {
            if (hovered) {
                closeTimer.stop();
                openTimer.restart();
            } else {
                openTimer.stop();
                closeTimer.restart();
            }
        }
    }
    Timer {
        id: openTimer
        interval: 150
        onTriggered: island.hovered = true
    }
    Timer {
        id: closeTimer
        interval: 300
        onTriggered: island.hovered = false
    }

    // Notificação com o mouse em cima: o tempo para (e recomeça ao sair).
    onHoveredChanged: {
        if (osd === "notification")
            hovered ? osdTimer.stop() : osdTimer.restart();
    }

    // Fecha o aviso temporário (volume/notificação).
    Timer {
        id: osdTimer
        onTriggered: island.osd = ""
    }

    // Volume: mostra o aviso quando o volume ou o mudo mudam.
    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource
    PwObjectTracker {
        objects: [island.sink, island.source]
    }
    Connections {
        target: island.sink?.audio ?? null
        function onVolumeChanged() { island.showOsd("volume", 2000); }
        function onMutedChanged() { island.showOsd("volume", 2000); }
    }

    // Microfone: aviso ao mutar/desmutar (tecla de microfone ou pavucontrol).
    Connections {
        target: island.source?.audio ?? null
        function onMutedChanged() {
            const muted = island.source.audio.muted;
            island.showToast(muted ? "\uf131" : "\uf130", muted ? "Microfone mudo" : "Microfone ligado",
                             muted ? Theme.red : Theme.green);
        }
    }

    // Caps Lock: lido da luz do teclado (Keyboard.qml).
    Connections {
        target: Keyboard
        function onCapsUpdated() {
            island.showToast("\u{f0632}", Keyboard.capsLock ? "Caps Lock ligado" : "Caps Lock desligado",
                             Keyboard.capsLock ? Theme.blue : Theme.overlay);
        }
    }

    // GameMode: aviso ao abrir/fechar um jogo (GameMode.qml).
    Connections {
        target: GameMode
        function onToggled() {
            island.showToast("\u{f0297}", GameMode.active ? "GameMode ativo · Desempenho" : "GameMode desligado",
                             GameMode.active ? Theme.green : Theme.overlay);
        }
    }

    // Brilho: os atalhos do Hyprland avisam via "qs ipc call brightness changed".
    Connections {
        target: Brightness
        function onUpdated() { island.showOsd("brightness", 2000); }
    }

    // Notificações: mostra o aviso (o serviço já ignora no "não perturbe").
    Connections {
        target: NotificationService
        function onReceived(n) {
            notificationView.notification = n;
            const critical = n.urgency === NotificationUrgency.Critical;
            island.showOsd("notification", n.expireTimeout > 0 ? n.expireTimeout : critical ? 10000 : 5000);
        }
    }

    // Launcher ou painel aberto: clicar fora da ilha fecha (o Hyprland avisa via "focus grab").
    HyprlandFocusGrab {
        windows: [island.window]
        active: island.launcherOpen || island.recordOpen || island.wallpaperOpen || island.keysOpen || island.powerOpen || island.centerOpen || island.connectionsOpen
        onCleared: {
            Launcher.close();
            NotificationService.centerOpen = false;
            QuickSettings.close();
            PowerMenu.close();
            Cheatsheet.close();
            Recorder.pickerOpen = false;
            Wallpaper.close();
        }
    }

    // Esc fecha o painel.
    focus: true
    Keys.onEscapePressed: {
        NotificationService.centerOpen = false;
        QuickSettings.close();
    }

    // ---------- Telas ----------

    CompactView {
        id: compactView
        shown: island.mode === "compact"
    }

    IslandView {
        id: mediaView
        shown: island.mode === "media"
        MediaRow {
            player: island.player
        }
    }

    VolumeView {
        id: volumeView
        shown: island.mode === "volume"
        sink: island.sink
    }

    ToastView {
        id: toastView
        shown: island.mode === "toast"
    }

    BrightnessView {
        id: brightnessView
        shown: island.mode === "brightness"
    }

    NotificationView {
        id: notificationView
        shown: island.mode === "notification"
        onHide: island.osd = ""
    }

    LauncherView {
        id: launcherView
        shown: island.mode === "launcher"
    }

    WallpaperView {
        id: wallpaperView
        shown: island.mode === "wallpaper"
    }

    RecordPickerView {
        id: recordView
        shown: island.mode === "record"
    }

    CheatsheetView {
        id: keysView
        shown: island.mode === "keys"
    }

    PowerView {
        id: powerView
        shown: island.mode === "power"
    }

    ConnectionsView {
        id: connectionsView
        shown: island.mode === "connections"
    }

    NotificationCenter {
        id: centerView
        shown: island.mode === "center"
    }

    HoverView {
        id: hoverView
        shown: island.mode === "hover"
        window: island.window
        player: island.player
    }
}
