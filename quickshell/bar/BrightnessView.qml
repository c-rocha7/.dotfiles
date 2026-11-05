// Aviso de brilho: ícone, barra e porcentagem.

import QtQuick
import qs

LevelView {
    icon: Brightness.value < 0.5 ? "\u{f00df}" : "\u{f00e0}"
    value: Brightness.value
    label: Math.round(Brightness.value * 100) + "%"
}
