//@ pragma UseQApplication
// (necessário para os menus da bandeja: Wi-Fi, Spotify, Vesktop...)

// Ponto de entrada do Quickshell (comando: qs).
// Cria a moldura (ou a ilha, conforme Theme.layout) em cada monitor e a tela de bloqueio.

import Quickshell
import qs
import qs.bar
import qs.frame
import qs.lock

ShellRoot {
    // Layout escolhido em Theme.layout: "moldura" (padrão) ou "ilha" (a de antes).
    Variants {
        model: Theme.layout === "moldura" ? Quickshell.screens : []

        // Cada monitor recebe a sua moldura; o monitor chega em "modelData".
        Frame {}
    }
    Variants {
        model: Theme.layout === "ilha" ? Quickshell.screens : []
        Bar {}
    }

    // Visão geral das workspaces (SUPER+Tab / 3 dedos para cima), nos dois layouts
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
