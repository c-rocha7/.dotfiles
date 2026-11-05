// Bateria: ícone + porcentagem. Fica vermelha abaixo de 20% fora da tomada.
// Some em computadores sem bateria.

import QtQuick
import qs

Pill {
    visible: Battery.available

    BarText {
        text: `${Battery.icon} ${Battery.percent}%`
        color: Battery.low ? Theme.red : Battery.pluggedIn ? Theme.green : Theme.text
    }
}
