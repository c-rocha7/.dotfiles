pragma Singleton

// Docker na central de controle: lista os containers e inicia/para/reinicia, abre logs e shell.
// Só consulta quando a central está aberta (não fica rodando "docker ps" o tempo todo) e não
// liga o serviço sozinho: se o Docker estiver parado, a página oferece um botão para iniciar.

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool watching: false           // a central (ou a página do Docker) está aberta
    property bool daemon: false             // o serviço está rodando
    property bool loaded: false
    property var containers: []             // [{ id, name, image, state, status, ports }]
    readonly property int runningCount: containers.filter(c => c.state === "running").length
    property string busy: ""                // nome do container com ação em andamento

    function refresh() {
        if (!lister.running)
            lister.running = true;
    }

    function act(name, action) {          // start | stop | restart | rm
        busy = name;
        actor.command = ["docker", action, name];
        actor.running = true;
    }
    function logs(name) {
        Quickshell.execDetached(["ghostty", "-e", "docker", "logs", "-f", "--tail", "300", name]);
    }
    function shell(name) {
        Quickshell.execDetached(["ghostty", "-e", "bash", "-c", `docker exec -it ${name} bash 2>/dev/null || docker exec -it ${name} sh`]);
    }
    function startDaemon() {
        // systemctl pede a senha pelo polkit (janela do KDE)
        Quickshell.execDetached(["bash", "-c", "systemctl start docker.socket docker.service"]);
        later.restart();
    }

    onWatchingChanged: if (watching) refresh()

    Process {
        id: lister
        command: ["bash", "-c", "systemctl is-active -q docker.service || { echo PARADO; exit 0; }; docker ps -a --format '{{json .}}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.loaded = true;
                if (text.trim() === "PARADO") {
                    root.daemon = false;
                    root.containers = [];
                    return;
                }
                root.daemon = true;
                const out = [];
                for (const line of text.split("\n")) {
                    if (line.trim() === "") continue;
                    try {
                        const j = JSON.parse(line);
                        out.push({
                            id: j.ID, name: j.Names, image: j.Image, state: j.State,
                            status: j.Status, ports: (j.Ports || "").replace(/0\.0\.0\.0:|\[::\]:/g, "")
                        });
                    } catch (e) {}
                }
                out.sort((a, b) => (b.state === "running") - (a.state === "running") || a.name.localeCompare(b.name));
                root.containers = out;
            }
        }
    }
    Process {
        id: actor
        onExited: {
            root.busy = "";
            root.refresh();
        }
    }
    Timer {
        id: later
        interval: 2500
        onTriggered: root.refresh()
    }
    Timer {
        running: root.watching
        interval: 4000
        repeat: true
        onTriggered: root.refresh()
    }
}
