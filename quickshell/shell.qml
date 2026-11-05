//@ pragma UseQApplication
// (necessário para os menus da bandeja: Wi-Fi, Spotify, Vesktop...)

// Ponto de entrada do Quickshell (comando: qs).
// Cria uma barra para cada monitor conectado e a tela de bloqueio.

import Quickshell
import qs.bar
import qs.lock

ShellRoot {
    Variants {
        model: Quickshell.screens

        // Cada monitor recebe o seu Bar; o monitor chega em "modelData".
        Bar {}
    }

    // Tela de bloqueio (só aparece quando bloqueado: qs ipc call lock lock)
    LockScreen {}
}
