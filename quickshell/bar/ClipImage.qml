// Mostra uma imagem do histórico do clipboard (clipvault).
// Na primeira vez, extrai a imagem para a pasta de cache do Quickshell; depois reaproveita.
// O nome do arquivo junta o id com o tamanho/dimensões, porque o clipvault reaproveita
// ids depois de "limpar histórico".

import QtQuick
import Quickshell
import Quickshell.Io
import qs

Item {
    id: root

    property string clipId: ""
    property string clipText: "" // ex.: "42kB image/png 1920x1080"
    property int previewWidth: 600

    readonly property string path: clipId === "" ? ""
        : `${Launcher.imageCache}/${clipId}_${clipText.replace(/[^0-9A-Za-z]/g, "")}.img`
    property string ready: ""

    onPathChanged: {
        ready = "";
        if (path !== "")
            extract.running = true;
    }
    Component.onCompleted: if (path !== "") extract.running = true

    Process {
        id: extract
        command: ["bash", "-c", 'mkdir -p "$(dirname "$1")" && { [ -s "$1" ] || clipvault get "$2" > "$1"; }',
            "_", root.path, root.clipId]
        onExited: code => {
            if (code === 0)
                root.ready = root.path;
        }
    }

    Image {
        anchors.fill: parent
        source: root.ready !== "" ? "file://" + root.ready : ""
        sourceSize.width: root.previewWidth
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        cache: false
    }
}
