pragma Singleton

// Cores, fonte, medidas e animações usadas em toda a configuração.
// "Singleton": existe uma única instância, acessada de qualquer arquivo como Theme.xxx.
// Paleta: do wallpaper (matugen) ou Catppuccin Mocha.

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: theme

    // ---------- Cores ----------
    // As cores vêm do wallpaper: a cada troca, o waypaper roda matugen/aplicar.sh, que gera
    // ~/.cache/matugen/quickshell.json (lido aqui na hora). Sem o arquivo: Catppuccin Mocha.
    // Voltar ao Catppuccin: matugen/aplicar.sh desligar (e "ligar" para voltar).
    readonly property bool wallpaperColors: true
    readonly property var wp: {
        if (!wallpaperColors) return {};
        try { return JSON.parse(colorsFile.text()); } catch (e) { return {}; }
    }
    function pick(name, fallback) { return wp[name] ?? fallback; }

    readonly property color island:   pick("island", "#11111b")   // fundo da ilha/moldura (quase preto)
    readonly property color base:     pick("base", "#1e1e2e")     // fundo dos blocos
    readonly property color surface0: pick("surface0", "#313244") // miniaturas, blocos dentro de blocos
    readonly property color surface1: pick("surface1", "#45475a") // hover / trilho das barras
    readonly property color overlay:  pick("overlay", "#6c7086")  // texto apagado
    readonly property color subtext:  pick("subtext", "#a6adc8")  // texto secundário
    readonly property color text:     pick("text", "#cdd6f4")
    readonly property color blue:     pick("blue", "#89b4fa")     // destaque (item ativo)
    readonly property color red:      pick("red", "#f38ba8")      // erro, desligar
    readonly property color green:    pick("green", "#a6e3a1")    // ok, mídia
    readonly property color yellow:   pick("yellow", "#f9e2af")   // aviso

    FileView {
        id: colorsFile
        path: Quickshell.env("HOME") + "/.cache/matugen/quickshell.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
    }

    // Fonte
    readonly property string font: "FiraCode Nerd Font Propo"
    readonly property int fontSize: 14

    // Medidas
    readonly property int barHeight: 30 // altura da ilha fechada
    readonly property int islandTop: 4  // distância da ilha até o topo da tela
    readonly property int radius: 10
    readonly property int gap: 5        // espaço entre blocos

    // Layout: "moldura" (barra no topo + borda em volta da tela, cantos de dentro arredondados)
    // ou "ilha" (a ilha dinâmica sozinha no topo). Trocar e recarregar: SUPER+SHIFT+Esc.
    readonly property string layout: "moldura"
    readonly property color frame: island      // cor da moldura (a mesma da ilha)
    readonly property int frameBar: 38         // altura da barra de cima
    readonly property int frameBorder: 8       // espessura das bordas laterais e de baixo
    readonly property int frameRadius: 14      // raio dos cantos de dentro (= rounding 12 + gaps_out 2 do Hyprland)
    readonly property color frameOutline: pick("outline", "#45475a")  // contorno do lado de dentro (separa a moldura das janelas)
    readonly property real frameOutlineWidth: 1.5
    // Moldura e fundos dos painéis translúcidos (o Hyprland desfoca o que está atrás: layer_rule
    // "moldura" no hyprland.lua). 1 = opaco.
    readonly property real frameOpacity: 0.86

    // Animações da ilha (ms)
    readonly property int resizeDuration: 450
    readonly property int fadeDuration: 180
}
