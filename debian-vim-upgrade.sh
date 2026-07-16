#!/usr/bin/env bash

set -euo pipefail

echo "=== Removing APT-installed Vim packages ==="
sudo apt remove -y vim vim-runtime vim-tiny vim-common

echo "=== Updating package lists ==="
sudo apt update

echo "=== Installing build dependencies ==="
sudo apt install -y \
  git \
  build-essential \
  make \
  gcc \
  libncurses5-dev \
  libncursesw5-dev \
  python3 \
  python3-dev \
  perl \
  libperl-dev \
  ruby \
  ruby-dev

echo "=== Preparing source directory ==="
cd /usr/local/src

sudo rm -rf vim

echo "=== Cloning Vim source ==="
sudo git clone https://github.com/vim/vim.git

cd vim

sudo chown -R "$USER:$USER" .

echo "=== Cleaning previous build artifacts ==="
make distclean 2>/dev/null || true
git reset --hard
git clean -xfd

echo "=== Configuring build ==="
./configure \
  --with-features=huge \
  --enable-multibyte \
  --enable-python3interp=yes \
  --enable-perlinterp=yes \
  --enable-rubyinterp=yes \
  --prefix=/usr/local

echo "=== Building Vim ==="
make -j"$(nproc)"

echo "=== Installing Vim ==="
sudo make install

if [ ! -x /usr/local/bin/vim ]; then
    echo "ERROR: Vim installation failed."
    exit 1
fi

echo
echo "=== Vim Installation Verification ==="

VIM_TAG=$(vim --version | awk '
/^VIM - Vi IMproved/ { ver=$5 }
/^Included patches:/ {
    patch=$3
    sub("1-","",patch)
    printf "v%s.%04d", ver, patch
    exit
}')

echo "Binary : $(which vim)"
echo "Version: ${VIM_TAG}"
echo "Release: https://github.com/vim/vim/releases/tag/${VIM_TAG}"

echo
vim --version | head -3

echo
echo "Vim installation completed successfully."