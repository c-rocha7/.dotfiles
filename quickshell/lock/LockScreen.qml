// Bloqueio seguro do Wayland: enquanto Lock.locked for true, cada monitor recebe uma
// LockSurface e nenhum outro programa recebe teclado ou mouse.

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs

WlSessionLock {
    locked: Lock.locked

    WlSessionLockSurface {
        color: Theme.island

        LockSurface {
            anchors.fill: parent
        }
    }
}
