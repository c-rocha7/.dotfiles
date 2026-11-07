// Desenho da moldura: a tela inteira pintada com um "furo" de cantos arredondados no meio.
// Barra em cima (frameBar), bordas finas nos outros lados (frameBorder) e um contorno por dentro.

import QtQuick
import QtQuick.Shapes
import qs

Shape {
    id: root

    preferredRendererType: Shape.CurveRenderer   // bordas lisas (antisserrilhado)

    ShapePath {
        fillColor: Theme.frame
        strokeWidth: -1
        fillRule: ShapePath.OddEvenFill

        PathRectangle {
            x: 0
            y: 0
            width: root.width
            height: root.height
        }
        PathRectangle {
            x: Theme.frameBorder
            y: Theme.frameBar
            width: root.width - 2 * Theme.frameBorder
            height: root.height - Theme.frameBar - Theme.frameBorder
            radius: Theme.frameRadius
        }
    }

    // Contorno do lado de dentro: deixa a moldura visível mesmo com wallpaper/janelas escuros.
    ShapePath {
        fillColor: "transparent"
        strokeColor: Theme.frameOutline
        strokeWidth: Theme.frameOutlineWidth

        PathRectangle {
            x: Theme.frameBorder - Theme.frameOutlineWidth / 2
            y: Theme.frameBar - Theme.frameOutlineWidth / 2
            width: root.width - 2 * Theme.frameBorder + Theme.frameOutlineWidth
            height: root.height - Theme.frameBar - Theme.frameBorder + Theme.frameOutlineWidth
            radius: Theme.frameRadius + Theme.frameOutlineWidth / 2
        }
    }
}
