// Página da bateria (central de controle): carga, tempo, consumo, saúde e perfil de energia.

import QtQuick
import Quickshell.Services.UPower
import qs
import qs.bar

Column {
    id: root

    readonly property UPowerDevice dev: UPower.displayDevice
    readonly property var bat: UPower.devices.values.find(d => d.isLaptopBattery) ?? dev

    function hm(seconds) {
        if (!seconds || seconds <= 0)
            return "";
        const h = Math.floor(seconds / 3600), m = Math.round((seconds % 3600) / 60);
        return h > 0 ? `${h} h ${m} min` : `${m} min`;
    }

    width: 352
    spacing: 10

    Row {
        spacing: 12
        BarText {
            text: Battery.icon
            font.pixelSize: 28
            color: Battery.low ? Theme.red : Battery.pluggedIn ? Theme.green : Theme.text
        }
        Column {
            anchors.verticalCenter: parent.verticalCenter
            ThemedText { text: `${Battery.percent}%`; font.pixelSize: 20; font.bold: true }
            ThemedText {
                font.pixelSize: 12
                color: Theme.subtext
                text: {
                    if (Battery.pluggedIn)
                        return root.bat.timeToFull > 0 ? `Carregando · cheia em ${root.hm(root.bat.timeToFull)}` : "Na tomada";
                    return root.bat.timeToEmpty > 0 ? `Na bateria · ${root.hm(root.bat.timeToEmpty)} restantes` : "Na bateria";
                }
            }
        }
    }

    Grid {
        columns: 2
        columnSpacing: 16
        rowSpacing: 4

        ThemedText { text: "Consumo"; color: Theme.subtext; font.pixelSize: 12 }
        ThemedText { text: root.bat.changeRate ? `${Math.abs(root.bat.changeRate).toFixed(1)} W` : "—"; font.pixelSize: 12 }
        ThemedText { text: "Saúde"; color: Theme.subtext; font.pixelSize: 12 }
        ThemedText {
            font.pixelSize: 12
            text: root.bat.healthSupported ? `${Math.round(root.bat.healthPercentage)}%` : "—"
        }
        ThemedText { text: "Capacidade"; color: Theme.subtext; font.pixelSize: 12 }
        ThemedText { text: root.bat.energyCapacity ? `${root.bat.energyCapacity.toFixed(1)} Wh` : "—"; font.pixelSize: 12 }
        ThemedText { text: "Limite de carga"; color: Theme.subtext; font.pixelSize: 12 }
        ThemedText { text: "80% (FlexiCharger, BIOS)"; font.pixelSize: 12 }
    }

    ThemedText { text: "Perfil de energia"; color: Theme.subtext; font.pixelSize: 12; font.bold: true }
    Row {
        spacing: 6
        Repeater {
            model: [
                { p: PowerProfile.PowerSaver, name: "Economia", icon: "\u{f032a}" },
                { p: PowerProfile.Balanced, name: "Equilíbrio", icon: "\u{f05d1}" },
                { p: PowerProfile.Performance, name: "Desempenho", icon: "\u{f04c5}" }
            ]
            CcTile {
                required property var modelData
                width: 112
                height: 44
                visible: modelData.p !== PowerProfile.Performance || PowerProfiles.hasPerformanceProfile
                icon: modelData.icon
                label: modelData.name
                active: PowerProfiles.profile === modelData.p
                onToggled: PowerProfiles.profile = modelData.p
            }
        }
    }
}
