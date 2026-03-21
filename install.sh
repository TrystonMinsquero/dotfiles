#!/bin/bash

# run with 
# curl -fsSL https://raw.githubusercontent.com/TrystonMinsquero/dotfiles/main/install.sh -o install.sh && vim install.sh && sudo ./install.sh && rm install.sh

echo "Installing packages..."
sudo apt install zsh fzf ripgrep stow lazygit git gh zip unzip

# Install oh-my-zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
sudo rm -rf /opt/nvim-linux-x86_64
sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz
sudo rm -rf nvim-linux-x86_64.tar.gz

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
stow nvim zshrc tmux

source ~/.zshrc

echo "Dotfiles setup complete!"

