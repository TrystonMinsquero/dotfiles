#!/bin/bash
# Copy dotfiles into place on Windows (run from Git Bash).
# Windows won't create symlinks without Developer Mode, so we copy instead.
# Re-run after editing anything in the repo. Targets that are already links to
# the repo are left alone; a differing target is backed up as <name>.~N~.

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
APPDATA_DIR="$(cygpath "$APPDATA")"
LOCALAPPDATA_DIR="$(cygpath "$LOCALAPPDATA")"

# repo path -> destination
place() {
  local src="$DOTFILES/$1" dst="$2"
  if [ -e "$dst" ] && [ "$src" -ef "$dst" ]; then
    echo "linked   $dst"
    return
  fi
  mkdir -p "$(dirname "$dst")"
  if [ -d "$src" ]; then
    mkdir -p "$dst"
    cp -r --backup=numbered "$src/." "$dst/"
  elif cmp -s "$src" "$dst"; then
    echo "same     $dst"
    return
  else
    cp --backup=numbered "$src" "$dst"
  fi
  echo "copied   $dst"
}

place wezterm/.wezterm.lua            "$HOME/.wezterm.lua"
place glazewm/config.yaml             "$HOME/.glzr/glazewm/config.yaml"
place kanata/.config/kanata/kanata.kbd "$APPDATA_DIR/kanata/kanata.kbd"
place nvim/.config/nvim               "$LOCALAPPDATA_DIR/nvim"
place ideavim/.ideavimrc              "$HOME/.ideavimrc"
