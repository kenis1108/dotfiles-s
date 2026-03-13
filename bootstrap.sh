#!/usr/bin/bash

if [ ! -d .local/bin ]; then
    mkdir -p .local/bin
fi

CHEZMOI_VERSION=2.70.0
CHEZMOI_RELEASE_URL=https://github.com/twpayne/chezmoi/releases/download/v${CHEZMOI_VERSION}/chezmoi_${CHEZMOI_VERSION}_linux_amd64.tar.gz
CHEZMOI_NAME=chezmoi.tar.gz
CHEZMOI_DIR=./.local/share/chezmoi

if [ -d $CHEZMOI_DIR ]; then
    rm -rf $CHEZMOI_DIR
fi
mkdir -p $CHEZMOI_DIR
curl -L -o $CHEZMOI_DIR/$CHEZMOI_NAME $CHEZMOI_RELEASE_URL
tar -xf $CHEZMOI_DIR/$CHEZMOI_NAME -C $CHEZMOI_DIR
rm -rf $CHEZMOI_DIR/$CHEZMOI_NAME
ln -sf $(pwd)/.local/share/chezmoi/chezmoi $(pwd)/.local/bin/chezmoi

if [ -d $HOME/.config/chezmoi ]; then
    rm -rf $HOME/.config/chezmoi
fi
mkdir -p $HOME/.config/chezmoi
cp ./chezmoi.yaml $HOME/.config/chezmoi/chezmoi.yaml

LAZYGIT_VERSION=0.60.0
LAZYGIT_RELEASE_URL=https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_linux_x86_64.tar.gz
LAZYGIT_NAME=lazygit.tar.gz
LAZYGIT_DIR=./.local/share/lazygit

if [ -d $LAZYGIT_DIR ]; then
    rm -rf $LAZYGIT_DIR
fi
mkdir -p $LAZYGIT_DIR
curl -L -o $LAZYGIT_DIR/$LAZYGIT_NAME $LAZYGIT_RELEASE_URL
tar -xf $LAZYGIT_DIR/$LAZYGIT_NAME -C $LAZYGIT_DIR
rm -rf $LAZYGIT_DIR/$LAZYGIT_NAME
ln -sf $(pwd)/.local/share/lazygit/lazygit $(pwd)/.local/bin/lazygit

YAZI_VERSION=26.1.22
YAZI_RELEASE_URL=https://github.com/sxyazi/yazi/releases/download/v${YAZI_VERSION}/yazi-x86_64-unknown-linux-gnu.zip
YAZI_NAME=yazi-x86_64-unknown-linux-gnu
YAZI_DIR=./.local/share/yazi

if [ -d $YAZI_DIR ]; then
    rm -rf $YAZI_DIR
fi
mkdir -p $YAZI_DIR
curl -L -o $YAZI_DIR/$YAZI_NAME.zip $YAZI_RELEASE_URL
unzip $YAZI_DIR/$YAZI_NAME.zip -d $YAZI_DIR
rm -rf $YAZI_DIR/$YAZI_NAME.zip
ln -sf $(pwd)/.local/share/yazi/$YAZI_NAME/yazi $(pwd)/.local/bin/yazi
ln -sf $(pwd)/.local/share/yazi/$YAZI_NAME/ya $(pwd)/.local/bin/ya