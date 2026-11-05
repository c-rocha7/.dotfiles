// Texto com a fonte e a cor do tema, sem posicionamento automático
// (para usar dentro de Column/Item; dentro de Row prefira o BarText).

import QtQuick
import qs

Text {
    color: Theme.text
    font.family: Theme.font
    font.pixelSize: Theme.fontSize
    font.weight: Font.DemiBold
    textFormat: Text.PlainText
}
