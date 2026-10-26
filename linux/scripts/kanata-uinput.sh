#!/bin/bash
# Lets kanata run as your user (no sudo): access to keyboards and /dev/uinput.
# Run as yourself (not with sudo); it asks for your password once.
# Log out and back in afterwards for the new groups to apply.
set -euo pipefail

if [ "$EUID" -eq 0 ]; then
    echo "Run this without sudo (it calls sudo itself)." >&2
    exit 1
fi

echo "==> kanata: granting $USER access to keyboards and /dev/uinput (sudo)"
sudo groupadd -f uinput
sudo usermod -aG input,uinput "$USER"
echo 'KERNEL=="uinput", MODE="0660", GROUP="uinput", OPTIONS+="static_node=uinput"' |
    sudo tee /etc/udev/rules.d/99-kanata-uinput.rules >/dev/null
echo uinput | sudo tee /etc/modules-load.d/uinput.conf >/dev/null
sudo modprobe uinput
sudo udevadm control --reload-rules
sudo udevadm trigger
echo "    log out and back in so the new groups apply"
