//@ pragma UseQApplication
// (necessário para os menus da bandeja: Wi-Fi, Spotify, Vesktop...)

// Ponto de entrada do Quickshell (comando: qs).
// Cria a moldura em cada monitor, a visão geral das workspaces e a tela de bloqueio.

import Quickshell
import qs
import qs.frame
import qs.lock

ShellRoot {
    // Moldura (barra + borda + painéis) em cada monitor; o monitor chega em "modelData".
    Variants {
        model: Quickshell.screens
        Frame {}
    }

    // Visão geral das workspaces (SUPER+Tab / 3 dedos para cima)
    Variants {
        model: Quickshell.screens
        OverviewWindow {}
    }

    // Prévia da tela de bloqueio (qs ipc call lock previa)
    Variants {
        model: Quickshell.screens
        LockPreview {}
    }

    // Tela de bloqueio (só aparece quando bloqueado: qs ipc call lock lock)
    LockScreen {}
}
