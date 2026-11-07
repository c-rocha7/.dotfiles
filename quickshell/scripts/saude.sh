#!/usr/bin/env bash
# Saúde do sistema para a central de controle (Health.qml): uma linha JSON, sem root.
#   serviços com falha (sistema e usuário), disco, memória, temperaturas (CPU, GPU, SSD),
#   últimos snapshots (root e home), travamentos desde o boot (coredumpctl), tempo ligado.
set -u

temp() {   # temp <nome do hwmon> → °C inteiro (vazio se não achar)
    for h in /sys/class/hwmon/hwmon*; do
        [ "$(cat "$h/name" 2>/dev/null)" = "$1" ] && [ -r "$h/temp1_input" ] && { echo $(( $(cat "$h/temp1_input") / 1000 )); return; }
    done
}
snap() {   # snap <config> → "número|data" do último snapshot
    snapper -c "$1" --csvout list --columns number,date 2>/dev/null | tail -1 | tr ',' '|'
}

falhas=$( { systemctl --failed --plain --no-legend 2>/dev/null | awk '{print $1}'
            systemctl --user --failed --plain --no-legend 2>/dev/null | awk '{print $1 " (usuário)"}'; } | jq -R . | jq -s .)
read -r _ total usado livre < <(df -B1 --output=target,size,used,avail / | tail -1)
mem_total=$(awk '/MemTotal/ {print $2*1024}' /proc/meminfo)
mem_livre=$(awk '/MemAvailable/ {print $2*1024}' /proc/meminfo)
# Travamentos desde o boot: [{hora, programa}] (o mais novo primeiro)
travamentos=$(coredumpctl list --no-pager --no-legend --since "$(uptime -s)" 2>/dev/null |
    awk '{print $3 "\t" $10}' | while IFS=$'\t' read -r hora exe; do
        printf '%s\t%s\n' "${hora:0:5}" "$(basename "$exe")"; done |
    jq -R 'split("\t") | {hora: .[0], programa: .[1]}' | jq -s 'reverse')

jq -cn \
    --argjson falhas "$falhas" \
    --arg disco_total "$total" --arg disco_usado "$usado" --arg disco_livre "$livre" \
    --arg mem_total "$mem_total" --arg mem_livre "$mem_livre" \
    --arg cpu "$(temp k10temp)" --arg gpu "$(temp amdgpu)" --arg ssd "$(temp nvme)" \
    --arg snap_root "$(snap root)" --arg snap_home "$(snap home)" \
    --argjson travamentos "${travamentos:-[]}" --arg ligado "$(awk '{s=int($1); d=int(s/86400); h=int(s%86400/3600); m=int(s%3600/60); printf (d ? d " d " : "") h " h " m " min"}' /proc/uptime)" \
    '{falhas: $falhas,
      disco: {total: ($disco_total|tonumber), usado: ($disco_usado|tonumber), livre: ($disco_livre|tonumber)},
      memoria: {total: ($mem_total|tonumber), livre: ($mem_livre|tonumber)},
      temp: {cpu: $cpu, gpu: $gpu, ssd: $ssd},
      snapshots: {root: $snap_root, home: $snap_home},
      travamentos: $travamentos, ligado: $ligado}'
