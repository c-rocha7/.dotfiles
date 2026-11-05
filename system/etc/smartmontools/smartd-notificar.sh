#!/usr/bin/env bash
# Chamado pelo smartd (como root) quando o SSD tem algum problema.
# Manda uma notificação crítica para cada usuário logado (aparece na ilha do Quickshell)
# e registra no log (journalctl -t smartd-notificar).
# Testar: sudo SMARTD_DEVICE=/dev/nvme0 SMARTD_FAILTYPE=Teste SMARTD_MESSAGE="Teste" /etc/smartmontools/smartd-notificar.sh

title="SSD: ${SMARTD_FAILTYPE:-aviso} (${SMARTD_DEVICE:-disco})"
body="${SMARTD_MESSAGE:-O smartd detectou um problema no disco.}
Detalhes: sudo smartctl -a ${SMARTD_DEVICE:-/dev/nvme0}"

logger -t smartd-notificar -- "$title: ${SMARTD_MESSAGE:-}"

while read -r uid user _; do
    [[ -n $user ]] || continue
    systemd-run --quiet --machine="$user@.host" --user \
        notify-send -u critical -a "Saúde do SSD" -i drive-harddisk "$title" "$body" || true
done < <(loginctl list-users --no-legend)
exit 0
