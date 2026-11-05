pragma Singleton

// Cores, fonte, medidas e animações usadas em toda a configuração.
// "Singleton": existe uma única instância, acessada de qualquer arquivo como Theme.xxx.
// Paleta: Catppuccin Mocha (a mesma do Waybar).

import QtQuick
import Quickshell

Singleton {
    // Cores
    readonly property color island:   "#11111b" // fundo da ilha (quase preto, como no iPhone)
    readonly property color base:     "#1e1e2e" // fundo dos blocos dentro da ilha
    readonly property color surface1: "#45475a" // hover / trilho da barra de volume
    readonly property color overlay:  "#6c7086" // texto apagado (dias de outro mês)
    readonly property color subtext:  "#a6adc8" // texto secundário
    readonly property color text:     "#cdd6f4"
    readonly property color blue:     "#89b4fa" // item ativo
    readonly property color red:      "#f38ba8" // botão de desligar
    readonly property color green:    "#a6e3a1" // mídia

    // Fonte
    readonly property string font: "FiraCode Nerd Font Propo"
    readonly property int fontSize: 14

    // Medidas
    readonly property int barHeight: 30 // altura da ilha fechada
    readonly property int islandTop: 4  // distância da ilha até o topo da tela
    readonly property int radius: 10
    readonly property int gap: 5        // espaço entre blocos

    // Animações da ilha (ms)
    readonly property int resizeDuration: 450
    readonly property int fadeDuration: 180
}
