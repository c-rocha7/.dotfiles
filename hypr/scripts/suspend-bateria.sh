#!/usr/bin/env bash
# Chamado pelo hypridle depois de 30 min parado: suspende só se estiver na bateria.
# Na tomada não faz nada (downloads e builds longos continuam).
# Vídeo tocando ou jogo aberto (GameMode) seguram o hypridle, então não chegam aqui.

for ac in /sys/class/power_supply/A*/online; do
    [[ -r $ac && $(<"$ac") == 1 ]] && exit 0
done
systemctl suspend
