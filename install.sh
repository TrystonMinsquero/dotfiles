#!/bin/bash

# run with 
# curl -fsSL https://raw.githubusercontent.com/TrystonMinsquero/dotfiles/main/install.sh -o install.sh && vim install.sh && sudo ./install.sh && rm install.sh

# Delete this once you've read the entire script 
echo "Read through this script so you know what you're installing!"
exit 1

# Install oh-my-zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

echo "Installing packages..."
sudo apt install neovim fzf ripgrep stow lazygit git gh

echo "Installation complete..."

git config --global user.name "Tryston Minsquero"
git config --global user.email "trystonminsquero@gmail.com"
git config --global init.defaultBranch "main"

# Clone dotfiles repository
if [ ! -d "$HOME/dotfiles" ]; then
  echo "Cloning dotfiles repository..."
  git clone https://github.com/TrystonMinsquero/dotfiles.git $HOME/dotfiles
fi

# Navigate to dotfiles directory
cd $HOME/dotfiles || exit

# Stow dotfiles packages
echo "Stowing dotfiles..."
stow nvim zshrc

source ~/.zshrc

echo "Dotfiles setup complete!"

