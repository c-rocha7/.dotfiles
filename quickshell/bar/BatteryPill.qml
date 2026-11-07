// Bateria: ícone + porcentagem. Fica vermelha abaixo de 20% fora da tomada.
// Some em computadores sem bateria.

import QtQuick
import qs

Pill {
    visible: Battery.available
    // Na moldura: clique abre a página da bateria na central de controle.
    clickable: true
    color: hovered && clickable ? Theme.surface1 : Theme.base
    onClicked: ControlCenter.toggle("battery")

    BarText {
        text: `${Battery.icon} ${Battery.percent}%`
        color: Battery.low ? Theme.red : Battery.pluggedIn ? Theme.green : Theme.text
    }
}
