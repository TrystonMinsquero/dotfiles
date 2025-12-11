# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="robbyrussell"

ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster"  "tjkirch_mod" "johnson")

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
plugins=(
    git
    gh
    # zsh-autosuggestions
)

if [ -f ~/.zshrc_plugs ]; then
	source ~/.zshrc_plugs
fi

source $ZSH/oh-my-zsh.sh

# User configuration

# vim mode for shell
set -o vi
# bindkey '^I' autosuggest-accept
# bindkey -M viins '^I^I' expand-or-complete

# Set up fzf key bindings and fuzzy completion
source <(fzf --zsh)

alias pbcopy="xlip -selection current"

alias py="python3"
alias lg="lazygit"
alias dot="cd ~/dotfiles"
alias dev="cd ~/dev"

export EDITOR="nvim"

# App Shortcuts
alias todo="nvim ~/.todo.md"
alias zshconf="nvim ~/.zshrc"
alias zshex="nvim ~/.zshrc_extra"
alias zshreload="source ~/.zshrc"
alias nvimconf="nvim ~/.config/nvim/init.lua"
alias ghosttyconf="nvim ~/.config/ghostty/config"
alias wezconf="nvim ~/.wezterm.lua"

export PATH="/snap/bin/:$PATH"
export PATH="$HOME/go/bin/:$PATH"

export XDG_CONFIG_HOME="$HOME/.config"

function grt()
{
    git rev-parse --show-toplevel
}

if [ -f ~/.fzf.zsh ]; then 
	# Use install version of fzf if it exists
	source ~/.fzf.zsh
else
	# Set up fzf key bindings and fuzzy completion
	source <(fzf --zsh)
fi

# Useful for having machine specific configs
if [ -f "$HOME/.zshrc_extra" ]; then
    source "$HOME/.zshrc_extra"
fi
