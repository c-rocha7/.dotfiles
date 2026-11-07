// Fundo de um painel que "brota" da moldura: mesma cor e mesmo contorno da moldura, com
// "orelhas" côncavas onde o painel encontra a borda (parece uma continuação dela).
//
// attach:
//   "top"      pendurado na barra de cima (orelhas à esquerda e à direita)
//   "topRight" no canto de cima à direita (orelha na barra e na borda direita)
//   "right"    saindo da borda direita (orelhas em cima e embaixo)
// (0, 0) é o canto de cima à esquerda do painel; as orelhas ficam para fora dele.

import QtQuick
import QtQuick.Shapes
import qs

Shape {
    id: root

    property string attach: "top"
    property real w: 0                 // tamanho atual do painel (anima ao abrir/fechar)
    property real h: 0
    readonly property real ear: Math.max(0, Math.min(Theme.frameRadius, attach === "right" ? w : h))
    readonly property real corner: Math.max(0, Math.min(Theme.frameRadius, w / 2, h / 2))
    readonly property real ow: Theme.frameOutlineWidth
    readonly property real m: Theme.frameRadius + 4  // folga do Shape para desenhar as orelhas

    property real ox: 0                // posição do painel (quando desenhado na camada de fundo)
    property real oy: 0
    x: ox - m
    y: oy - m
    width: w + 2 * m
    height: h + 2 * m
    visible: w > 0.5 && h > 0.5
    preferredRendererType: Shape.CurveRenderer

    // Monta o contorno em coordenadas do painel e desloca pela folga "m".
    function p(x, y) { return `${x + m},${y + m}`; }

    readonly property string outlinePath: {
        const R = ear, r = corner, W = w, H = h;
        if (attach === "top")
            return `M ${p(-R, 0)} A ${R} ${R} 0 0 1 ${p(0, R)} L ${p(0, H - r)} A ${r} ${r} 0 0 0 ${p(r, H)}`
                 + ` L ${p(W - r, H)} A ${r} ${r} 0 0 0 ${p(W, H - r)} L ${p(W, R)} A ${R} ${R} 0 0 1 ${p(W + R, 0)}`;
        if (attach === "topRight")
            return `M ${p(-R, 0)} A ${R} ${R} 0 0 1 ${p(0, R)} L ${p(0, H - r)} A ${r} ${r} 0 0 0 ${p(r, H)}`
                 + ` L ${p(W - R, H)} A ${R} ${R} 0 0 1 ${p(W, H + R)}`;
        // right
        return `M ${p(W, -R)} A ${R} ${R} 0 0 1 ${p(W - R, 0)} L ${p(r, 0)} A ${r} ${r} 0 0 0 ${p(0, r)}`
             + ` L ${p(0, H - r)} A ${r} ${r} 0 0 0 ${p(r, H)} L ${p(W - R, H)} A ${R} ${R} 0 0 1 ${p(W, H + R)}`;
    }

    // Preenchimento: o contorno fechado por dentro da moldura, cobrindo também a linha de
    // contorno da moldura no trecho onde o painel encosta (ow + 1 px para dentro da borda).
    readonly property string fillPath: {
        const R = ear, W = w, H = h, c = ow + 1;
        if (attach === "top")
            return `M ${p(-R, -c)} L ${outlinePath.slice(2)} L ${p(W + R, -c)} Z`;
        if (attach === "topRight")
            return `M ${p(-R, -c)} L ${outlinePath.slice(2)} L ${p(W + c, H + R)} L ${p(W + c, -c)} Z`;
        return `M ${p(W + c, -R)} L ${outlinePath.slice(2)} L ${p(W + c, H + R)} Z`;
    }

    ShapePath {
        fillColor: Theme.frame
        strokeWidth: -1
        PathSvg { path: root.fillPath }
    }

    ShapePath {
        fillColor: "transparent"
        strokeColor: Theme.frameOutline
        strokeWidth: root.ow
        capStyle: ShapePath.FlatCap
        PathSvg { path: root.outlinePath }
    }
}
