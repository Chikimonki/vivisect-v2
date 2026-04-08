#!/bin/bash
# ~/vivisect/scripts/install_arsenal_final.sh
# The definitive toolchain. Run once. Never again.

set -euo pipefail

echo "[*] Installing base system tools..."
sudo apt update
sudo apt install -y \
    build-essential \
    gdb gdb-multiarch \
    radare2 \
    binutils \
    hexedit xxd \
    strace ltrace \
    file patchelf \
    elfutils nasm \
    perl \
    curl wget git \
    cmake pkg-config \
    libssl-dev \
    tmux \
    llvm-18 llvm-18-dev clang-18

echo "[*] Installing LuaJIT (from source, GC64 enabled)..."
cd /tmp
git clone https://luajit.org/git/luajit.git
cd luajit
make -j$(nproc) XCFLAGS=-DLUAJIT_ENABLE_GC64
sudo make install
sudo ldconfig
luajit -v

echo "[*] Installing Odin (from source)..."
cd /tmp
git clone https://github.com/odin-lang/Odin.git
cd Odin
make release
sudo mkdir -p /opt/odin
sudo cp -r . /opt/odin/
sudo ln -sf /opt/odin/odin /usr/local/bin/odin
odin version

echo "[*] Installing Go..."
GO_VERSION="1.23.4"
cd /tmp
wget -q "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz"
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> ~/.bashrc
export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin
go version

echo "[*] Installing Julia (optional, for SIMD madness in later chapters)..."
curl -fsSL https://install.julialang.org | sh -s -- --yes

echo "[*] Python (minimal, emergency use only)..."
sudo rm -f /usr/lib/python3.*/EXTERNALLY-MANAGED 2>/dev/null || true
pip3 install --user --break-system-packages lief capstone 2>/dev/null || \
    pip3 install --user lief capstone

echo ""
echo "============================================"
echo "[+] Arsenal Locked and Loaded"
echo "============================================"
echo "LuaJIT:  $(luajit -v 2>&1)"
echo "Odin:    $(odin version | head -1)"
echo "Go:      $(go version)"
echo "Perl:    $(perl -e 'print $^V')"
echo "r2:      $(r2 -v 2>&1 | head -1)"
echo "GDB:     $(gdb --version | head -1)"
echo "============================================"
echo ""
echo "Primary weapons:  LuaJIT + Odin"
echo "Support:          Go + Perl"
echo "Emergency:        Python (in the drawer)"
echo "Docker:           Sleeping (wakes Chapter 5)"
echo ""
