#!/usr/bin/env bash
set -eo pipefail 2>/dev/null || set -e

echo "[bootstrap] Starting dotfiles installation..."

if [[ "$SHELL" != */fish ]]; then
  echo "[bootstrap] Changing shell to fish..."
  sudo chsh "$(id -un)" --shell "/usr/bin/fish" 2>/dev/null || echo "[bootstrap] Could not change shell (requires manual intervention)"
fi

if [ ! -d $HOME/.local/bin ]; then
  echo "[bootstrap] Creating ~/.local/bin..."
  mkdir -p $HOME/.local/bin
fi

CHEZMOI_VERSION=2.70.0
CHEZMOI_RELEASE_URL="https://github.com/twpayne/chezmoi/releases/download/v${CHEZMOI_VERSION}/chezmoi_${CHEZMOI_VERSION}_linux_amd64.tar.gz"
CHEZMOI_NAME=chezmoi.tar.gz
CHEZMOI_DIR=$HOME/.local/opt/chezmoi

if [ -d "$CHEZMOI_DIR" ]; then
  rm -rf "$CHEZMOI_DIR"
fi
mkdir -p "$CHEZMOI_DIR"
echo "[bootstrap] Downloading chezmoi ${CHEZMOI_VERSION}..."
curl -fsSL -o "$CHEZMOI_DIR/$CHEZMOI_NAME" "$CHEZMOI_RELEASE_URL"
tar -xf "$CHEZMOI_DIR/$CHEZMOI_NAME" -C "$CHEZMOI_DIR"
rm -f "$CHEZMOI_DIR/$CHEZMOI_NAME"
ln -sf "$HOME/.local/opt/chezmoi/chezmoi" "$HOME/.local/bin/chezmoi"
echo "[bootstrap] chezmoi installed"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
echo "[bootstrap] Script directory: $SCRIPT_DIR"

if [ -d "$HOME/.config/chezmoi" ]; then
  echo "[bootstrap] Removing existing chezmoi config..."
  rm -rf "$HOME/.config/chezmoi"
fi
mkdir -p "$HOME/.config/chezmoi"
printf 'sourceDir = "%s"\n' "$SCRIPT_DIR" > "$HOME/.config/chezmoi/chezmoi.toml"
echo "[bootstrap] chezmoi configured"

LAZYGIT_VERSION=0.60.0
LAZYGIT_RELEASE_URL="https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_linux_x86_64.tar.gz"
LAZYGIT_NAME=lazygit.tar.gz
LAZYGIT_DIR=$HOME/.local/opt/lazygit

if [ -d "$LAZYGIT_DIR" ]; then
  rm -rf "$LAZYGIT_DIR"
fi
mkdir -p "$LAZYGIT_DIR"
echo "[bootstrap] Downloading lazygit ${LAZYGIT_VERSION}..."
curl -fsSL -o "$LAZYGIT_DIR/$LAZYGIT_NAME" "$LAZYGIT_RELEASE_URL"
tar -xf "$LAZYGIT_DIR/$LAZYGIT_NAME" -C "$LAZYGIT_DIR"
rm -f "$LAZYGIT_DIR/$LAZYGIT_NAME"
ln -sf "$HOME/.local/opt/lazygit/lazygit" "$HOME/.local/bin/lazygit"
echo "[bootstrap] lazygit installed"

YAZI_VERSION=26.1.22
YAZI_RELEASE_URL="https://github.com/sxyazi/yazi/releases/download/v${YAZI_VERSION}/yazi-x86_64-unknown-linux-gnu.zip"
YAZI_NAME=yazi-x86_64-unknown-linux-gnu
YAZI_DIR=$HOME/.local/opt/yazi

if [ -d "$YAZI_DIR" ]; then
  rm -rf "$YAZI_DIR"
fi
mkdir -p "$YAZI_DIR"
echo "[bootstrap] Downloading yazi ${YAZI_VERSION}..."
curl -fsSL -o "$YAZI_DIR/$YAZI_NAME.zip" "$YAZI_RELEASE_URL"
unzip -q "$YAZI_DIR/$YAZI_NAME.zip" -d "$YAZI_DIR"
mv "$YAZI_DIR/$YAZI_NAME"/* "$YAZI_DIR/"
rmdir "$YAZI_DIR/$YAZI_NAME"
rm -f "$YAZI_DIR/$YAZI_NAME.zip"
ln -sf "$HOME/.local/opt/yazi/yazi" "$HOME/.local/bin/yazi"
ln -sf "$HOME/.local/opt/yazi/ya" "$HOME/.local/bin/ya"
echo "[bootstrap] yazi installed"

NVIM_VERSION=nightly
NVIM_RELEASE_URL="https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}/nvim-linux-x86_64.tar.gz"
NVIM_NAME=nvim-linux-x86_64
NVIM_DIR=$HOME/.local/opt/nvim

if [ -d "$NVIM_DIR" ]; then
  rm -rf "$NVIM_DIR"
fi
mkdir -p "$NVIM_DIR"
echo "[bootstrap] Downloading neovim ${NVIM_VERSION}..."
curl -fsSL -o "$NVIM_DIR/${NVIM_NAME}.tar.gz" "$NVIM_RELEASE_URL"
tar -xzf "$NVIM_DIR/${NVIM_NAME}.tar.gz" -C "$NVIM_DIR"
mv "$NVIM_DIR/$NVIM_NAME"/* "$NVIM_DIR/"
rmdir "$NVIM_DIR/$NVIM_NAME"
rm -f "$NVIM_DIR/${NVIM_NAME}.tar.gz"
ln -sf "$HOME/.local/opt/nvim/bin/nvim" "$HOME/.local/bin/nvim"
echo "[bootstrap] neovim installed"

STARSHIP_VERSION=1.25.0
STARSHIP_RELEASE_URL="https://github.com/starship/starship/releases/download/v${STARSHIP_VERSION}/starship-x86_64-unknown-linux-gnu.tar.gz"
STARSHIP_DIR=$HOME/.local/opt/starship

if [ -d "$STARSHIP_DIR" ]; then
  rm -rf "$STARSHIP_DIR"
fi
mkdir -p "$STARSHIP_DIR"
echo "[bootstrap] Downloading starship ${STARSHIP_VERSION}..."
curl -fsSL -o "$STARSHIP_DIR/starship.tar.gz" "$STARSHIP_RELEASE_URL"
tar -xzf "$STARSHIP_DIR/starship.tar.gz" -C "$STARSHIP_DIR"
rm -f "$STARSHIP_DIR/starship.tar.gz"
ln -sf "$HOME/.local/opt/starship/starship" "$HOME/.local/bin/starship"
echo "[bootstrap] starship installed"

ZELLIJ_VERSION=0.44.1
ZELLIJ_RELEASE_URL="https://github.com/zellij-org/zellij/releases/download/v${ZELLIJ_VERSION}/zellij-x86_64-unknown-linux-musl.tar.gz"
ZELLIJ_DIR=$HOME/.local/opt/zellij

if [ -d "$ZELLIJ_DIR" ]; then
  rm -rf "$ZELLIJ_DIR"
fi
mkdir -p "$ZELLIJ_DIR"
echo "[bootstrap] Downloading zellij ${ZELLIJ_VERSION}..."
curl -fsSL -o "$ZELLIJ_DIR/zellij.tar.gz" "$ZELLIJ_RELEASE_URL"
tar -xzf "$ZELLIJ_DIR/zellij.tar.gz" -C "$ZELLIJ_DIR"
rm -f "$ZELLIJ_DIR/zellij.tar.gz"
ln -sf "$HOME/.local/opt/zellij/zellij" "$HOME/.local/bin/zellij"
echo "[bootstrap] zellij installed"

if command -v npm &>/dev/null; then
  echo "[bootstrap] Installing opencode-ai..."
  npm install -g opencode-ai 2>/dev/null
  echo "[bootstrap] opencode-ai installed"
fi

chezmoi apply && echo "[bootstrap] Dotfiles applied"
