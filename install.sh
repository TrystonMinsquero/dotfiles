#!/bin/bash

# Delete this once you've read the entire script 
echo "Read through this script so you know what you're installing!"
exit 1

# Install oh-my-zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
## install zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-autosuggestions.git $ZSH_CUSTOM/plugins/zsh-autosuggestions
## install zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting

# Homebrew
## Install
echo "Installing Brew..."
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew analytics off

## Formulae
echo "Installing Brew Formulae..."


## Core Utils
# echo "Install gnu coreutils"
# brew install coreutils

### Must Have things
# brew install zsh-autosuggestions
# brew install zsh-syntax-highlighting
brew install stow
# brew install fzf
brew install bat
brew install make
brew install ripgrep

### Terminal
brew install git
brew install lazygit
brew install neovim

## Casks


echo "Installation complete..."

# Clone dotfiles repository
if [ ! -d "$HOME/dotfiles" ]; then
  echo "Cloning dotfiles repository..."
  git clone https://github.com/TrystonMinsquero/dotfiles.git $HOME/dotfiles
fi

# Navigate to dotfiles directory
cd $HOME/dotfiles || exit

# Stow dotfiles packages
echo "Stowing dotfiles..."
stow -t ~ *

source ~/.zshrc

echo "Dotfiles setup complete!"

git config --global user.name "Tryston Minsquero"
git config --global user.email "trystonminsquero@gmail.com"
git config --global init.defaultBranch "main"
