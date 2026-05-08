#!/usr/bin/env bash
set -euo pipefail

arch=$(uname -m)
case "$arch" in
  x86_64)  arch_name="x86_64" ;;
  arm64)   arch_name="arm64" ;;
  *)       echo "Unknown architecture: $arch" && exit 1 ;;
esac

cd ~/.local/opt
rm -rf "nvim-macos-${arch_name}.tar.gz"
curl -LO "https://github.com/neovim/neovim/releases/download/nightly/nvim-macos-${arch_name}.tar.gz"
rm -rf "nvim-macos-${arch_name}"
tar -xf "nvim-macos-${arch_name}.tar.gz"
