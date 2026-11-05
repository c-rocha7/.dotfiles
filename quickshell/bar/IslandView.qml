// Base de cada "tela" da ilha: centraliza o conteúdo, soma o espaçamento interno
// e faz o efeito de aparecer/sumir (opacidade + leve zoom).

import QtQuick
import qs

Item {
    id: root

    default property alias content: box.data
    property bool shown: false
    property int padH: 16 // espaço nas laterais
    property int padV: 0  // espaço em cima/embaixo

    implicitWidth: box.childrenRect.width + padH * 2
    implicitHeight: Math.max(Theme.barHeight, box.childrenRect.height + padV * 2)
    anchors.centerIn: parent

    opacity: shown ? 1 : 0
    scale: shown ? 1 : 0.92
    visible: opacity > 0
    enabled: shown

    Behavior on opacity {
        NumberAnimation { duration: Theme.fadeDuration }
    }
    Behavior on scale {
        NumberAnimation { duration: Theme.fadeDuration }
    }

    Item {
        id: box
        anchors.centerIn: parent
        width: childrenRect.width
        height: childrenRect.height
    }
}
