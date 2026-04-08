#!/bin/bash
# Vivisect Arsenal Installer - Final Form
set -e

echo "[*] Installing base packages..."
sudo apt update
sudo apt install -y \
    build-essential \
    gdb \
    radare2 \
    luajit \
    binutils \
    strace \
    ltrace \
    ne \
    libcapstone-dev \
    curl \
    wget \
    git \
    cmake

echo "[*] Installing Zig 0.14.0..."
if ! command -v zig &> /dev/null; then
    cd /tmp
    wget -q https://ziglang.org/download/0.14.0/zig-linux-x86_64-0.14.0.tar.xz
    tar xf zig-linux-x86_64-0.14.0.tar.xz
    sudo mv zig-linux-x86_64-0.14.0 /opt/zig
    sudo ln -sf /opt/zig/zig /usr/local/bin/zig
fi
zig version

echo "[*] Installing Keystone (from source)..."
if ! ldconfig -p | grep -q libkeystone; then
    cd /tmp
    git clone --depth 1 https://github.com/keystone-engine/keystone.git
    cd keystone
    mkdir -p build && cd build
    cmake -DCMAKE_BUILD_TYPE=Release ..
    make -j$(nproc)
    sudo make install
    sudo ldconfig
fi

echo "[*] Setting up aliases..."
if ! grep -q "alias viv=" ~/.bashrc; then
    echo "alias viv='cd ~/vivisect'" >> ~/.bashrc
fi

echo ""
echo "╔═══════════════════════════════════════╗"
echo "║   Vivisect Arsenal Installed          ║"
echo "╚═══════════════════════════════════════╝"
echo ""
echo "LuaJIT:   $(luajit -v 2>&1 | head -1)"
echo "Zig:      $(zig version)"
echo "r2:       $(r2 -v 2>&1 | head -1 | cut -d' ' -f1-2)"
echo "Capstone: $(ldconfig -p | grep -q libcapstone && echo OK || echo MISSING)"
echo "Keystone: $(ldconfig -p | grep -q libkeystone && echo OK || echo MISSING)"
echo ""
echo "Type 'source ~/.bashrc' then 'viv' to enter the lab."
FINAL_ARSENAL
