#!/usr/bin/env bash
# KDE Plasma layer. Called by ../install.sh; safe to run on its own and to re-run.
#
#   kwin/          GlazeWM-style workspaces script (stowed)
#   kanata-modes/  remembers kanata's mode per app (stowed, user service)
#   fish/          KDE logout/shutdown abbreviations (stowed)
#   plasma/        workspace bar, system stats widget, Glaze panel theme
#                  (installed as copies: Plasma won't load symlinked packages)
#   panel.js       builds the top panel if it isn't there yet
set -euo pipefail
cd "$(dirname "$0")"
KW() { kwriteconfig6 "$@"; }

echo "==> kde: stowing kwin kanata-modes fish"
stow -d . -t ~ --no-folding --restow kwin kanata-modes fish
systemctl --user daemon-reload

echo "==> kde: plasma widgets and theme"
for pkg in glaze.workspacebar glaze.sysinfo; do
    kpackagetool6 -t Plasma/Applet -u "plasma/$pkg" >/dev/null 2>&1 ||
        kpackagetool6 -t Plasma/Applet -i "plasma/$pkg" >/dev/null
done
# kpackagetool can install a theme but not find it again to upgrade, so copy it.
rm -rf ~/.local/share/plasma/desktoptheme/glaze
mkdir -p ~/.local/share/plasma/desktoptheme
cp -r plasma/glaze-theme ~/.local/share/plasma/desktoptheme/glaze
plasma-apply-desktoptheme glaze >/dev/null

echo "==> kde: settings"
KW --file kwinrc --group Plugins --key glaze-workspacesEnabled true
KW --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnRight AX   # no minimize button
KW --file kdeglobals --group General --key TerminalApplication wezterm
KW --file kdeglobals --group General --key TerminalService org.wezfurlong.wezterm.desktop
KW --file ksmserverrc --group General --key excludeApps steam             # don't reopen Steam at login
if command -v arch-update >/dev/null; then                                # CachyOS/Arch update tray icon
    mkdir -p ~/.config/arch-update
    grep -qx ShowTrayWhenRelevant ~/.config/arch-update/arch-update.conf 2>/dev/null ||
        echo ShowTrayWhenRelevant >> ~/.config/arch-update/arch-update.conf
fi
qdbus6 org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true

echo "==> kde: shortcuts"
# Key codes are Qt's: Meta 0x10000000, Alt 0x08000000, Ctrl 0x04000000, Shift 0x02000000.
shortcut() { # component action keys...  (no keys = unbind)
    local keys="@ai []"
    [ $# -gt 2 ] && keys="[$(IFS=,; echo "${*:3}")]"
    gdbus call --session --dest org.kde.kglobalaccel --object-path /kglobalaccel \
        --method org.kde.KGlobalAccel.setForeignShortcut "['$1','$2','','']" "$keys" >/dev/null 2>&1 ||
        echo "    couldn't set $1/$2 (log in to Plasma and re-run)"
}
shortcut org.kde.krunner.desktop _launch 268435488 134217760 150994993 16777362  # Meta+Space, Alt+Space, Alt+F2, Search
shortcut org.kde.konsole.desktop _launch                       # Ctrl+Alt+T is WezTerm's new tab
shortcut org.kde.screenreader.desktop toggleScreenReader       # frees Meta+Alt+S for workspace S
shortcut org.kde.spectacle.desktop RecordScreen                # frees Meta+Alt+R for workspace R
shortcut "KDE Keyboard Layout Switcher" "Switch to Next Keyboard Layout"        # frees Meta+Alt+K (focus up)
shortcut "KDE Keyboard Layout Switcher" "Switch to Last-Used Keyboard Layout"   # frees Meta+Alt+L (focus right)
for dir in Up Down Left Right; do shortcut kwin "Switch Window $dir"; done      # Meta+Alt+arrows
shortcut plasmashell cycle-panels 402653231                    # Meta+Alt+/ (Meta+Alt+. switches windows)

echo "==> kde: panel"
out=$(qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$(cat panel.js)")
tray=$(echo "$out" | grep -o 'tray=[0-9]*' | cut -d= -f2 || true)
if [ -n "$tray" ]; then
    # Tray icons the stats widget replaces, or that are just noise. Set with
    # plasmashell stopped, otherwise it overwrites the file on exit.
    hidden="org.kde.plasma.bluetooth,org.kde.plasma.weather,discord_status_icon_1,org.kde.plasma.keyboardlayout"
    hidden="$hidden,org.kde.plasma.clipboard,org.kde.plasma.brightness,org.kde.plasma.volume"
    hidden="$hidden,org.kde.plasma.networkmanagement,org.kde.plasma.battery"
    systemctl --user stop plasma-plasmashell
    KW --file plasma-org.kde.plasma.desktop-appletsrc --group Containments --group "$(echo "$out" | grep -o 'panel=[0-9]*' | cut -d= -f2)" \
        --group Applets --group "$tray" --group General --key hiddenItems "$hidden"
    systemctl --user start plasma-plasmashell
    echo "    built the top panel"
else
    echo "    panel already set up, left alone"
fi

echo "==> kde: services"
systemctl --user enable --now kanata-modes.service >/dev/null
