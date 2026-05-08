#!/usr/bin/env bash

rm -rf ~/.config/nvim_lazyvim
git clone https://github.com/LazyVim/starter ~/.config/nvim_lazyvim

rm -rf ~/.config/nvim_nvchad
git clone https://github.com/NvChad/starter ~/.config/nvim_nvchad

ln -sf $HOME/.config/nvim/lua $HOME/.config/nvim_nvchad/lua/origin_configs

ln -sf $HOME/.config/nvim/lua $HOME/.config/nvim_lazyvim/lua/origin_configs
