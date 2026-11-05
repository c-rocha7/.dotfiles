// Texto padrão da barra (fonte, tamanho e cor do tema).

import QtQuick
import qs

Text {
    color: Theme.text
    font.family: Theme.font
    font.pixelSize: Theme.fontSize
    font.weight: Font.DemiBold
    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
}
