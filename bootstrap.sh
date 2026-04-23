#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if [[ "$SHELL" != */fish ]]; then
  sudo chsh "$(id -un)" --shell "/usr/bin/fish"
fi

if [ ! -d .local/bin ]; then
  mkdir -p .local/bin
fi

CHEZMOI_VERSION=2.70.0
CHEZMOI_RELEASE_URL="https://github.com/twpayne/chezmoi/releases/download/v${CHEZMOI_VERSION}/chezmoi_${CHEZMOI_VERSION}_linux_amd64.tar.gz"
CHEZMOI_NAME=chezmoi.tar.gz
CHEZMOI_DIR=./.local/opt/chezmoi

if [ -d "$CHEZMOI_DIR" ]; then
  rm -rf "$CHEZMOI_DIR"
fi
mkdir -p "$CHEZMOI_DIR"
curl -fL -o "$CHEZMOI_DIR/$CHEZMOI_NAME" "$CHEZMOI_RELEASE_URL"
tar -xf "$CHEZMOI_DIR/$CHEZMOI_NAME" -C "$CHEZMOI_DIR"
rm -f "$CHEZMOI_DIR/$CHEZMOI_NAME"
ln -sf "$(pwd)/.local/opt/chezmoi/chezmoi" "$(pwd)/.local/bin/chezmoi"

if [ -d "$HOME/.config/chezmoi" ]; then
  rm -rf "$HOME/.config/chezmoi"
fi
mkdir -p "$HOME/.config/chezmoi"
cp "./chezmoi.yaml" "$HOME/.config/chezmoi/chezmoi.yaml"

LAZYGIT_VERSION=0.60.0
LAZYGIT_RELEASE_URL="https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_linux_x86_64.tar.gz"
LAZYGIT_NAME=lazygit.tar.gz
LAZYGIT_DIR=./.local/opt/lazygit

if [ -d "$LAZYGIT_DIR" ]; then
  rm -rf "$LAZYGIT_DIR"
fi
mkdir -p "$LAZYGIT_DIR"
curl -fL -o "$LAZYGIT_DIR/$LAZYGIT_NAME" "$LAZYGIT_RELEASE_URL"
tar -xf "$LAZYGIT_DIR/$LAZYGIT_NAME" -C "$LAZYGIT_DIR"
rm -f "$LAZYGIT_DIR/$LAZYGIT_NAME"
ln -sf "$(pwd)/.local/opt/lazygit/lazygit" "$(pwd)/.local/bin/lazygit"

YAZI_VERSION=26.1.22
YAZI_RELEASE_URL="https://github.com/sxyazi/yazi/releases/download/v${YAZI_VERSION}/yazi-x86_64-unknown-linux-gnu.zip"
YAZI_NAME=yazi-x86_64-unknown-linux-gnu
YAZI_DIR=./.local/opt/yazi

if [ -d "$YAZI_DIR" ]; then
  rm -rf "$YAZI_DIR"
fi
mkdir -p "$YAZI_DIR"
curl -fL -o "$YAZI_DIR/$YAZI_NAME.zip" "$YAZI_RELEASE_URL"
unzip -q "$YAZI_DIR/$YAZI_NAME.zip" -d "$YAZI_DIR"
rm -f "$YAZI_DIR/$YAZI_NAME.zip"
ln -sf "$(pwd)/.local/opt/yazi/$YAZI_NAME/yazi" "$(pwd)/.local/bin/yazi"
ln -sf "$(pwd)/.local/opt/yazi/$YAZI_NAME/ya" "$(pwd)/.local/bin/ya"

NVIM_VERSION=nightly
NVIM_RELEASE_URL="https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}/nvim-linux-x86_64.tar.gz"
NVIM_NAME=nvim-linux-x86_64
NVIM_DIR=./.local/opt/nvim

if [ -d "$NVIM_DIR" ]; then
  rm -rf "$NVIM_DIR"
fi
mkdir -p "$NVIM_DIR"
curl -fL -o "$NVIM_DIR/${NVIM_NAME}.tar.gz" "$NVIM_RELEASE_URL"
tar -xzf "$NVIM_DIR/${NVIM_NAME}.tar.gz" -C "$NVIM_DIR"
rm -f "$NVIM_DIR/${NVIM_NAME}.tar.gz"
ln -sf "$(pwd)/.local/opt/nvim/$NVIM_NAME/bin/nvim" "$(pwd)/.local/bin/nvim"

STARSHIP_VERSION=1.25.0
STARSHIP_RELEASE_URL="https://github.com/starship/starship/releases/download/v${STARSHIP_VERSION}/starship-x86_64-unknown-linux-gnu.tar.gz"
STARSHIP_DIR=./.local/opt/starship

if [ -d "$STARSHIP_DIR" ]; then
  rm -rf "$STARSHIP_DIR"
fi
mkdir -p "$STARSHIP_DIR"
curl -fL -o "$STARSHIP_DIR/starship.tar.gz" "$STARSHIP_RELEASE_URL"
tar -xzf "$STARSHIP_DIR/starship.tar.gz" -C "$STARSHIP_DIR"
rm -f "$STARSHIP_DIR/starship.tar.gz"
ln -sf "$(pwd)/.local/opt/starship/starship" "$(pwd)/.local/bin/starship"

