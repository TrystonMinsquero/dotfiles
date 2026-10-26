#!/bin/sh
# Prints key=value lines for the System Stats widget:
#   cpu=      CPU temperature (millidegrees C, k10temp)
#   memavail= available RAM (kB)
#   memtotal= total RAM (kB)
#   gpu=      NVIDIA GPU runtime status (active / suspended / removed)
#   app=      memory of the focused app (kB, PSS summed over its process tree)
#   wifi=     Wi-Fi connection name, empty when disconnected
#   signal=   Wi-Fi signal (%)
#   net=      NetworkManager connectivity: full / limited / portal / none / unknown
#   bat=      battery charge (%)
#   batstate= Charging / Discharging / Full / Not charging
#   batcharge= / batcurrent= remaining charge (uAh) and current draw (uA), for time left
# Only reads /sys and /proc (plus one cheap nmcli call), so it never wakes the
# NVIDIA GPU or triggers a Wi-Fi scan.

for h in /sys/class/hwmon/hwmon*; do
    [ "$(cat "$h/name")" = k10temp ] && echo "cpu=$(cat "$h/temp1_input")"
done

awk '/^MemAvailable:/{a=$2} /^MemTotal:/{t=$2} END{print "memavail=" a; print "memtotal=" t}' /proc/meminfo

# No NVIDIA device at all = switched off completely (supergfxctl Integrated mode)
gpu=removed
for d in /sys/bus/pci/devices/*; do
    [ "$(cat "$d/vendor")" = 0x10de ] && case $(cat "$d/class") in 0x03*) gpu=$(cat "$d/power/runtime_status") ;; esac
done
echo "gpu=$gpu"

if [ -n "$1" ] && [ "$1" -gt 0 ] 2>/dev/null; then
    # The app's PID plus all of its descendants (browsers and Electron apps are many processes)
    pids=$(ps -eo pid=,ppid= | awk -v root="$1" '
        { parent[$1] = $2 }
        END { for (p in parent) { x = p; while (x > 1) { if (x == root) { print p; break } x = parent[x] } } }')
    total=0
    for p in $pids; do
        v=$(awk '/^Pss:/{print $2}' "/proc/$p/smaps_rollup" 2>/dev/null)
        total=$((total + ${v:-0}))
    done
    echo "app=$total"
fi

echo "wifi=$(nmcli -t -f TYPE,STATE,CONNECTION device 2>/dev/null | awk -F: '$1 == "wifi" && $2 == "connected" { print $3; exit }')"
echo "net=$(nmcli -t networking connectivity 2>/dev/null)"
# Link quality is out of 70
awk 'NR > 2 { gsub(/\./, "", $3); printf "signal=%d\n", $3 * 100 / 70; exit }' /proc/net/wireless

for b in /sys/class/power_supply/BAT*; do
    echo "bat=$(cat "$b/capacity")"
    echo "batstate=$(cat "$b/status")"
    echo "batcharge=$(cat "$b/charge_now" 2>/dev/null)"
    echo "batcurrent=$(cat "$b/current_now" 2>/dev/null)"
    break
done
