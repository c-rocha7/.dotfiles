pragma Singleton

// Servidor de notificações (substitui o swaync).
// O Quickshell passa a receber todas as notificações do sistema (D-Bus).
//
// - history: histórico, mais nova primeiro: [{ n: Notification, time: Date }]
// - dnd: "não perturbe" (não mostra avisos na ilha, mas guarda no histórico)
// - centerOpen: painel de notificações aberto
// - received(n): emitido a cada notificação nova (se o dnd estiver desligado)
//
// Também pode ser controlado pelo terminal / atalhos:
//   qs ipc call notifications toggle      abre/fecha o painel
//   qs ipc call notifications toggleDnd   liga/desliga o "não perturbe"
//   qs ipc call notifications clear       apaga todas

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

Singleton {
    id: root

    property var history: []
    property bool dnd: false
    property bool centerOpen: false

    signal received(Notification n)

    function add(n, time) {
        n.tracked = true; // mantém a notificação viva até ser dispensada
        history = [{ n: n, time: time }, ...history];
        n.closed.connect(() => history = history.filter(e => e.n !== n));
    }

    function clearAll() {
        for (const e of history.slice())
            e.n.dismiss();
    }

    // Executa a ação padrão (ex.: abrir a conversa). Retorna false se não houver.
    function invokeDefault(n) {
        for (const action of n.actions) {
            if (action.identifier === "default") {
                action.invoke();
                return true;
            }
        }
        return false;
    }

    // Descobre o melhor ícone: imagem enviada > ícone do app > ícone do .desktop.
    // Retorna "" se nada for encontrado (a interface mostra um sino no lugar).
    function iconFor(n) {
        if (n.image)
            return n.image;

        const icon = n.appIcon;
        if (icon) {
            if (icon.startsWith("/"))
                return "file://" + icon;
            if (icon.includes("://"))
                return icon;
            const path = Quickshell.iconPath(icon, true);
            if (path)
                return path;
        }

        const entry = DesktopEntries.byId(n.desktopEntry) ?? DesktopEntries.heuristicLookup(n.appName);
        if (entry?.icon)
            return Quickshell.iconPath(entry.icon, true);

        return "";
    }

    NotificationServer {
        id: server

        keepOnReload: true // não perde as notificações quando a config recarrega
        actionsSupported: true
        bodySupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: n => {
            root.add(n, new Date());
            if (!root.dnd)
                root.received(n);
        }
    }

    // Depois de recarregar a config, reconstrói o histórico a partir do servidor.
    Component.onCompleted: {
        for (const n of server.trackedNotifications.values)
            add(n, new Date());
    }

    IpcHandler {
        target: "notifications"

        function toggle(): void { root.centerOpen = !root.centerOpen; }
        function toggleDnd(): void { root.dnd = !root.dnd; }
        function clear(): void { root.clearAll(); }
    }
}
