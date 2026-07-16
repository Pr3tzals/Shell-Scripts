#!/usr/bin/env bash

set -euo pipefail

echo "=== RHEL Vim Upgrade Script ==="

# Verify sudo access
if ! sudo -v; then
    echo "ERROR: This script requires sudo privileges."
    exit 1
fi

echo
echo "=== Removing existing Vim packages ==="
sudo dnf remove -y vim

echo
echo "=== Installing build dependencies ==="
sudo dnf install -y \
    gcc \
    make \
    git \
    ncurses \
    ncurses-devel \
    python3 \
    python3-devel \
    perl \
    perl-devel \
    ruby \
    ruby-devel

echo
echo "=== Preparing source directory ==="
cd /usr/local/src

sudo rm -rf vim

echo
echo "=== Cloning Vim source ==="
sudo git clone https://github.com/vim/vim.git

cd vim

sudo chown -R "$(id -un):$(id -gn)" .

echo
echo "=== Cleaning previous build artifacts ==="
make distclean 2>/dev/null || true
git reset --hard
git clean -xfd

echo
echo "=== Configuring Vim ==="
./configure \
    --with-features=huge \
    --enable-multibyte \
    --enable-python3interp=yes \
    --enable-perlinterp=yes \
    --enable-rubyinterp=yes \
    --prefix=/usr/local

echo
echo "=== Building Vim ==="
make -j"$(nproc)"

echo
echo "=== Installing Vim ==="
sudo make install

echo
echo "=== Setting Vim as default ==="

if [ -f /usr/bin/vim ]; then
    sudo mv /usr/bin/vim /usr/bin/vim.backup.$(date +%Y%m%d-%H%M%S)
fi

sudo ln -sf /usr/local/bin/vim /usr/bin/vim

if [ ! -x /usr/local/bin/vim ]; then
    echo "ERROR: Vim installation failed."
    exit 1
fi

echo
echo "=== Vim Installation Verification ==="

VIM_TAG=$(
    vim --version | awk '
    /^VIM - Vi IMproved/ {
        ver=$5
    }
    /^Included patches:/ {
        patch=$3
        sub("1-","",patch)
        printf "v%s.%04d", ver, patch
        exit
    }'
)

echo "Binary : $(which vim)"
echo "Version: ${VIM_TAG}"
echo "Release: https://github.com/vim/vim/releases/tag/${VIM_TAG}"

echo
vim --version | head -3

echo
echo "Vim installation completed successfully."
