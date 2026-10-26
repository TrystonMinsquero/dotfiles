#!/usr/bin/env bash
# Linux layer. Called by ../install.sh; safe to run on its own and to re-run.
#
#   kanata/   kanata as a user service + its config from common/ (stowed),
#             uinput permissions (sudo, once)
#   memento/  memento mori wallpaper + daily timer (stowed)
#   kde/      only when running KDE Plasma
#   laptop/  only when the machine has a battery
set -euo pipefail
cd "$(dirname "$0")"

echo "==> linux: kanata (config + service)"
stow -d ../common -t ~ --restow kanata
stow -d . -t ~ --no-folding --restow kanata
if ! id -nG | grep -qw uinput; then
    ./scripts/kanata-uinput.sh   # asks for sudo; needs a re-login afterwards
fi
systemctl --user daemon-reload
systemctl --user enable kanata.service

echo "==> linux: memento wallpaper"
stow -d . -t ~ --no-folding --restow memento
systemctl --user daemon-reload
if [ ! -s ~/.config/memento/birthdate ]; then
    read -rp "    Birth date (YYYY-MM-DD, empty to skip): " bday
    [ -n "$bday" ] && mkdir -p ~/.config/memento && echo "$bday" > ~/.config/memento/birthdate
fi
if [ -s ~/.config/memento/birthdate ]; then
    systemctl --user enable --now memento-wallpaper.timer >/dev/null
fi

if [ "${XDG_CURRENT_DESKTOP:-}" = KDE ] || command -v plasmashell >/dev/null; then
    ./kde/install.sh
else
    echo "==> kde: skipped (not KDE Plasma)"
fi

if ls /sys/class/power_supply/BAT* >/dev/null 2>&1; then
    ./laptop/install.sh
else
    echo "==> laptop: skipped (no battery)"
fi
