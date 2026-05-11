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

YAZI_VERSION=26.5.6
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

FZF_VERSION=0.72.0
FZF_RELEASE_URL="https://github.com/junegunn/fzf/releases/download/v${FZF_VERSION}/fzf-${FZF_VERSION}-linux_amd64.tar.gz"
FZF_NAME=fzf.tar.gz
FZF_DIR=$HOME/.local/opt/fzf

if [ -d "$FZF_DIR" ]; then
  rm -rf "$FZF_DIR"
fi
mkdir -p "$FZF_DIR"
echo "[bootstrap] Downloading fzf ${FZF_VERSION}..."
curl -fsSL -o "$FZF_DIR/$FZF_NAME" "$FZF_RELEASE_URL"
tar -xzf "$FZF_DIR/$FZF_NAME" -C "$FZF_DIR"
rm -f "$FZF_DIR/$FZF_NAME"
ln -sf "$HOME/.local/opt/fzf/fzf" "$HOME/.local/bin/fzf"
echo "[bootstrap] fzf installed"

ZOXIDE_VERSION=0.9.9
ZOXIDE_RELEASE_URL="https://github.com/ajeetdsouza/zoxide/releases/download/v${ZOXIDE_VERSION}/zoxide-${ZOXIDE_VERSION}-x86_64-unknown-linux-musl.tar.gz"
ZOXIDE_DIR=$HOME/.local/opt/zoxide

if [ -d "$ZOXIDE_DIR" ]; then
  rm -rf "$ZOXIDE_DIR"
fi
mkdir -p "$ZOXIDE_DIR"
echo "[bootstrap] Downloading zoxide ${ZOXIDE_VERSION}..."
curl -fsSL -o "$ZOXIDE_DIR/zoxide.tar.gz" "$ZOXIDE_RELEASE_URL"
tar -xzf "$ZOXIDE_DIR/zoxide.tar.gz" -C "$ZOXIDE_DIR"
rm -f "$ZOXIDE_DIR/zoxide.tar.gz"
ln -sf "$HOME/.local/opt/zoxide/zoxide" "$HOME/.local/bin/zoxide"
echo "[bootstrap] zoxide installed"

EZA_VERSION=0.23.4
EZA_RELEASE_URL="https://github.com/eza-community/eza/releases/download/v${EZA_VERSION}/eza_x86_64-unknown-linux-musl.tar.gz"
EZA_DIR=$HOME/.local/opt/eza

if [ -d "$EZA_DIR" ]; then
  rm -rf "$EZA_DIR"
fi
mkdir -p "$EZA_DIR"
echo "[bootstrap] Downloading eza ${EZA_VERSION}..."
curl -fsSL -o "$EZA_DIR/eza.tar.gz" "$EZA_RELEASE_URL"
tar -xzf "$EZA_DIR/eza.tar.gz" -C "$EZA_DIR"
rm -f "$EZA_DIR/eza.tar.gz"
ln -sf "$HOME/.local/opt/eza/eza" "$HOME/.local/bin/eza"
echo "[bootstrap] eza installed"

FD_VERSION=10.4.2
FD_RELEASE_URL="https://github.com/sharkdp/fd/releases/download/v${FD_VERSION}/fd-v${FD_VERSION}-x86_64-unknown-linux-musl.tar.gz"
FD_DIR=$HOME/.local/opt/fd

if [ -d "$FD_DIR" ]; then
  rm -rf "$FD_DIR"
fi
mkdir -p "$FD_DIR"
echo "[bootstrap] Downloading fd ${FD_VERSION}..."
curl -fsSL -o "$FD_DIR/fd.tar.gz" "$FD_RELEASE_URL"
tar -xzf "$FD_DIR/fd.tar.gz" -C "$FD_DIR" --strip-components=1
rm -f "$FD_DIR/fd.tar.gz"
ln -sf "$HOME/.local/opt/fd/fd" "$HOME/.local/bin/fd"
echo "[bootstrap] fd installed"

RG_VERSION=15.1.0
RG_RELEASE_URL="https://github.com/BurntSushi/ripgrep/releases/download/${RG_VERSION}/ripgrep-${RG_VERSION}-x86_64-unknown-linux-musl.tar.gz"
RG_DIR=$HOME/.local/opt/ripgrep

if [ -d "$RG_DIR" ]; then
  rm -rf "$RG_DIR"
fi
mkdir -p "$RG_DIR"
echo "[bootstrap] Downloading ripgrep ${RG_VERSION}..."
curl -fsSL -o "$RG_DIR/rg.tar.gz" "$RG_RELEASE_URL"
tar -xzf "$RG_DIR/rg.tar.gz" -C "$RG_DIR" --strip-components=1
rm -f "$RG_DIR/rg.tar.gz"
ln -sf "$HOME/.local/opt/ripgrep/rg" "$HOME/.local/bin/rg"
echo "[bootstrap] ripgrep installed"

if command -v npm &>/dev/null; then
  echo "[bootstrap] Installing opencode-ai..."
  npm install -g opencode-ai 2>/dev/null
  echo "[bootstrap] opencode-ai installed"
fi

chezmoi apply && echo "[bootstrap] Dotfiles applied"
