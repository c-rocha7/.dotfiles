// Perfil de energia (power-profiles-daemon).
// Clique: alterna Economia → Equilíbrio → Desempenho.

import QtQuick
import Quickshell.Services.UPower
import qs

Pill {
    id: root

    readonly property var names: ({
            [PowerProfile.PowerSaver]: "  Economia",
            [PowerProfile.Balanced]: "  Equilíbrio",
            [PowerProfile.Performance]: "  Desempenho"
        })

    clickable: true
    color: hovered ? Theme.surface1 : Theme.base

    BarText {
        text: root.names[PowerProfiles.profile] ?? ""
        color: PowerProfiles.profile === PowerProfile.PowerSaver ? Theme.green
             : PowerProfiles.profile === PowerProfile.Performance ? Theme.red
             : Theme.text
    }

    onClicked: {
        const order = [PowerProfile.PowerSaver, PowerProfile.Balanced];
        if (PowerProfiles.hasPerformanceProfile)
            order.push(PowerProfile.Performance);
        const next = (order.indexOf(PowerProfiles.profile) + 1) % order.length;
        PowerProfiles.profile = order[next];
    }
}
