// Painel que brota da moldura. Cresce a partir da borda ao abrir (o conteúdo desliza para
// fora dela) e recolhe ao fechar. Fechado, tem tamanho zero (não bloqueia cliques).
//
// Uso:  FramePanel { attach: "top"; shown: ...; body: v; LauncherView { id: v; shown: parent... } }
// O tamanho vem do conteúdo (implicitWidth/Height de "body") + "pad".
// Quem cria o painel posiciona com x/y (o canto de cima à esquerda do painel).

import QtQuick
import qs

Item {
    id: root

    default property alias content: inner.data
    property bool shown: false
    property string attach: "top"      // top | topRight | right (ver PanelShape)
    property Item body                 // o conteúdo principal (define o tamanho)
    property int pad: 10

    readonly property real fullWidth: (body ? body.implicitWidth : 0) + 2 * pad
    readonly property real fullHeight: (body ? body.implicitHeight : 0) + 2 * pad

    property real progress: shown ? 1 : 0
    Behavior on progress {
        NumberAnimation {
            duration: 260
            easing.type: Easing.OutCubic
        }
    }

    width: attach === "right" ? fullWidth * progress : fullWidth
    height: attach === "right" ? fullHeight : fullHeight * progress
    visible: progress > 0.001

    // Camada de fundo da moldura (FrameWindow.background): o fundo do painel é desenhado lá,
    // junto com a moldura, e a camada inteira fica translúcida de uma vez (sem costura escura
    // onde o painel encosta na borda). O conteúdo fica aqui, opaco, por cima.
    property Item background: null

    PanelShape {
        parent: root.background ?? root
        ox: root.background ? root.x : 0
        oy: root.background ? root.y : 0
        attach: root.attach
        w: root.width
        h: root.height
    }

    // O conteúdo tem sempre o tamanho final; a janela recortada revela aos poucos.
    Item {
        anchors.fill: parent
        clip: true

        Item {
            id: inner
            width: root.fullWidth
            height: root.fullHeight
            // top/topRight: desce da barra; right: sai da borda direita
            y: root.attach === "right" ? 0 : root.height - root.fullHeight
            x: root.attach === "right" ? root.width - root.fullWidth : 0
        }
    }
}
