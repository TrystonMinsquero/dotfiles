#!/usr/bin/env bash
# ASUS laptop settings (G-Helper-style battery life). Needs sudo.
# Called by ../install.sh when asusctl is installed; safe to re-run.
#
#   - CPU boost off on battery, on when plugged in (udev runs cpu-boost)
#   - Quiet profile on battery, Performance on AC
#   - Battery charge limit 80%
#   - supergfxd uses the ASUS firmware switch, so Integrated mode keeps the
#     NVIDIA GPU powered off even after sleep
#   - Slash LED bar on the lid off
set -euo pipefail
cd "$(dirname "$0")"
asus() { asusctl "$@" 2>&1 | grep -v 'Multiple asusd' || true; }

echo "==> asus: power settings (sudo)"
sudo install -m 755 cpu-boost /usr/local/bin/cpu-boost
sudo install -m 644 99-ac-power.rules /etc/udev/rules.d/99-ac-power.rules
sudo udevadm control --reload
sudo udevadm trigger --subsystem-match=power_supply --action=add   # apply cpu-boost now
sudo sed -i -E \
    -e 's|platform_profile_on_battery: [A-Za-z]+|platform_profile_on_battery: Quiet|' \
    -e 's|platform_profile_on_ac: [A-Za-z]+|platform_profile_on_ac: Performance|' \
    -e 's|change_platform_profile_on_(battery\|ac): false|change_platform_profile_on_\1: true|' \
    /etc/asusd/asusd.ron
sudo systemctl restart asusd
sleep 1
asus battery limit 80 >/dev/null

if command -v supergfxctl >/dev/null; then
    echo "==> asus: supergfxd uses the firmware GPU switch"
    # no_logind false: mode switches wait for a logout instead of killing
    # everything that uses the NVIDIA GPU (KWin included)
    sudo sed -i -E \
        -e 's|"hotplug_type": "[A-Za-z]+"|"hotplug_type": "Asus"|' \
        -e 's|"no_logind": [a-z]+|"no_logind": false|' \
        /etc/supergfxd.conf
    sudo systemctl enable --now supergfxd >/dev/null 2>&1
    sudo systemctl restart supergfxd
    if asus armoury get gpu_mux_mode | grep -q '(0)'; then
        echo "    NOTE: the GPU MUX is in discrete mode, so the NVIDIA GPU can't turn off."
        echo "    Run 'asusctl armoury set gpu_mux_mode 1' and reboot (may need a BIOS visit)."
    fi
else
    echo "    supergfxctl not installed (yay -S supergfxctl) - skipping GPU switching"
fi

echo "==> asus: Slash LED off"
asus slash set --disable -l 0 -B false -S false -s false -b false -w false >/dev/null
