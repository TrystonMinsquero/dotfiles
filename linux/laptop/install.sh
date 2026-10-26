#!/usr/bin/env bash
# Laptop layer. Called by ../install.sh only when the machine has a battery.
#
#   KDE:   Power Saver on battery, screen at 60 Hz on battery / max Hz on AC
#   asus/  ASUS-only power and hardware settings (sudo), when asusctl exists
set -euo pipefail
cd "$(dirname "$0")"
KW() { kwriteconfig6 --file powerdevilrc "$@"; }

if command -v kwriteconfig6 >/dev/null && command -v kscreen-doctor >/dev/null; then
    echo "==> laptop: KDE power profiles"
    KW --group Battery --group Performance --key PowerProfile power-saver
    KW --group LowBattery --group Performance --key PowerProfile power-saver

    # Internal screen at its current resolution: lowest refresh rate >= 60 for
    # battery, highest for AC. KDE runs these when it switches power profiles.
    read -r out low high < <(kscreen-doctor -j | python3 -I -c '
import json, sys
for o in json.load(sys.stdin)["outputs"]:
    if not o["name"].startswith("eDP") or not o.get("connected"):
        continue
    modes = o["modes"]
    size = next(m["size"] for m in modes if m["id"] == o["currentModeId"])
    rates = sorted({round(m["refreshRate"]) for m in modes if m["size"] == size})
    res = "%dx%d" % (size["width"], size["height"])
    print(o["name"], res + "@" + str(min(r for r in rates if r >= 60)), res + "@" + str(rates[-1]))
    break')
    if [ -n "${out:-}" ]; then
        for group in Battery LowBattery; do
            KW --group $group --group RunScript --key ProfileLoadCommand "kscreen-doctor output.$out.mode.$low"
        done
        KW --group AC --group RunScript --key ProfileLoadCommand "kscreen-doctor output.$out.mode.$high"
        echo "    $out: $low on battery, $high on AC"
    fi
    qdbus6 org.kde.Solid.PowerManagement /org/kde/Solid/PowerManagement \
        org.kde.Solid.PowerManagement.reparseConfiguration >/dev/null 2>&1 || true
fi

if command -v asusctl >/dev/null; then
    ./asus/install.sh
else
    echo "==> asus: skipped (asusctl not installed)"
fi
