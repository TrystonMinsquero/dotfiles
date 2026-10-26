source /usr/share/cachyos-fish-config/cachyos-config.fish

fish_vi_key_bindings

# !! = last command, !$ = last argument (e.g. `sudo !!`). Abbreviations expand
# on space/enter and survive fish_vi_key_bindings, which resets key bindings.
function __last_command
    echo $history[1]
end
function __last_argument
    echo (string split ' ' -- $history[1])[-1]
end
abbr -a !! --position anywhere --function __last_command
abbr -a '!$' --position anywhere --function __last_argument

# Clipboard: pipe into `cb`
switch (uname -a)
    case '*icrosoft*'
        alias cb="clip.exe"
    case '*Darwin*'
        alias cb="pbcopy"
    case '*'
        if set -q WAYLAND_DISPLAY
            alias cb="wl-copy"
        else
            alias cb="xclip -selection clipboard"
        end
end

alias py="python3"
alias lg="lazygit"
alias dot="cd ~/dotfiles"
alias dev="cd ~/dev"

set -gx EDITOR nvim
set -gx XDG_CONFIG_HOME $HOME/.config

# App Shortcuts
alias fishconf="nvim ~/.config/fish/config.fish"
alias fishex="nvim ~/.config/fish/extra.fish"
alias fishreload="source ~/.config/fish/config.fish"
alias zshconf="nvim ~/.zshrc"
alias nvimconf="nvim ~/.config/nvim/init.lua"
alias ghosttyconf="nvim ~/.config/ghostty/config"
alias wezconf="nvim ~/.wezterm.lua"
alias tmuxconf="nvim ~/.tmux.conf"

# -g: this session only, so it doesn't pile up in fish_variables.
# Folders that don't exist are skipped.
fish_add_path -g /snap/bin ~/go/bin ~/.local/bin ~/.local/share/nvim/mason/bin ~/.cargo/bin

# Git repo root
function grt
    git rev-parse --show-toplevel
end

# Machine-specific config (like .zshrc_extra)
if test -f ~/.config/fish/extra.fish
    source ~/.config/fish/extra.fish
end
