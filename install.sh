#!/usr/bin/env bash
# Set up this machine from the dotfiles. Safe to re-run any time.
#
#   common/   cross-platform configs (nvim, wezterm and claude stowed on every OS)
#   linux/    Linux layer (KDE and laptop parts only apply when detected)
#   windows/  Windows layer (run windows/install.sh from Git Bash)
set -euo pipefail
cd "$(dirname "$0")"

# Git, on every OS
echo "==> git"
git config --global user.name >/dev/null || git config --global user.name "Tryston Minsquero"
git config --global user.email >/dev/null || git config --global user.email "trystonminsquero@gmail.com"
git config --global init.defaultBranch main
git config --global submodule.recurse true

case "$(uname -s)" in
    MINGW* | MSYS* | CYGWIN*) exec ./windows/install.sh ;;
esac

command -v stow >/dev/null || { echo "Install GNU stow first." >&2; exit 1; }

# Only these are stowed on every machine; kanata comes with linux/ (it needs
# the service) and the rest of common/ can be stowed by hand: stow -d common -t ~ fish
PACKAGES="nvim wezterm"

# Stow won't overwrite real files, so move any of those aside to <file>.bak first.
stow_common() {
    stow -n -d common -t ~ --restow "$@" 2>&1 |
        sed -n 's/.*existing target \(.*\) since.*/\1/p' | while read -r target; do
            echo "    moving ~/$target to ~/$target.bak"
            mv ~/"$target" ~/"$target.bak"
        done
    stow -d common -t ~ --restow "$@"
}

echo "==> common: stowing $PACKAGES"
stow_common $PACKAGES

# Links only the files inside ~/.claude, never the folder itself, since Claude
# Code keeps its own state there
echo "==> common: stowing claude"
stow_common --no-folding claude

if [ "$(uname -s)" = Linux ]; then
    ./linux/install.sh
fi

echo "==> done"
