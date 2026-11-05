pragma Singleton

// Bateria do notebook (via UPower).
// - percent, pluggedIn, low, icon: usados pela ilha
// - avisa com uma notificação ao chegar em 15% e 5% (fora da tomada)
// - troca o perfil de energia sozinho ao tirar/colocar o carregador (autoProfile)
// Obs.: a BIOS limita a carga em 80%, então "carregado" costuma parar em 80%.

import QtQuick
import Quickshell
import Quickshell.Services.UPower

Singleton {
    id: root

    readonly property UPowerDevice device: UPower.displayDevice
    readonly property bool available: device.isLaptopBattery
    readonly property int percent: Math.round(device.percentage * 100)
    readonly property bool pluggedIn: !UPower.onBattery
    readonly property bool low: available && !pluggedIn && percent <= 20

    // Ícones de bateria (Nerd Font): vazia, 10%, 20% ... 90%, cheia.
    readonly property var levels: ["\u{f008e}", "\u{f007a}", "\u{f007b}", "\u{f007c}", "\u{f007d}",
        "\u{f007e}", "\u{f007f}", "\u{f0080}", "\u{f0081}", "\u{f0082}", "\u{f0079}"]
    readonly property string icon: pluggedIn ? "\u{f0084}" // carregando
        : levels[Math.min(10, Math.floor(percent / 10))]

    // Avisos de bateria fraca (cada nível avisa uma vez por descarga).
    property var warned: []

    function warn(level, urgency) {
        if (warned.includes(level))
            return;
        warned = [...warned, level];
        Quickshell.execDetached(["notify-send", "-u", urgency, "-i", "battery-caution",
            "-a", "Bateria", "Bateria fraca", `Restam ${percent}%. Conecte o carregador.`]);
    }

    onPercentChanged: {
        if (!available || pluggedIn)
            return;
        if (percent <= 5)
            warn(5, "critical");
        else if (percent <= 15)
            warn(15, "normal");
    }

    // Perfil de energia automático: Economia na bateria, Equilíbrio na tomada.
    // Só age na troca (tirar/colocar o carregador); depois disso você pode mudar à vontade.
    property bool autoProfile: true

    onPluggedInChanged: {
        if (pluggedIn)
            warned = [];
        if (autoProfile && available)
            PowerProfiles.profile = pluggedIn ? PowerProfile.Balanced : PowerProfile.PowerSaver;
    }
}
