#!/bin/bash
set -e

echo "[*] Final Arsenal Check (Python-Free Edition)"
echo "=============================================="

echo -n "LuaJIT:     "; luajit -v 2>&1 | head -1 | cut -d' ' -f1-2
echo -n "Odin:       "; ODIN_NO_GUI=1 DISPLAY= odin version 2>&1 | grep -v "QStandardPaths" | head -1
echo -n "Go:         "; go version | cut -d' ' -f3
echo -n "Perl:       "; perl -e 'print $^V' && echo
echo -n "r2:         "; r2 -v 2>&1 | head -1 | cut -d' ' -f1-2
echo -n "GDB:        "; gdb --version | head -1 | cut -d' ' -f1-4
echo -n "Capstone:   "; ldconfig -p | grep -q "libcapstone.so" && echo "OK" || echo "MISSING"
echo -n "Keystone:   "; ldconfig -p | grep -q "libkeystone.so" && echo "OK" || echo "MISSING"
echo -n "pwndbg:     "; gdb --batch -ex 'pi print("OK")' 2>&1 | grep -q OK && echo "OK" || echo "MISSING"
echo -n "rr:         "; which rr > /dev/null && echo "OK" || echo "MISSING"
echo -n "ROP tool:   "; (which ropr || which rp++ || which ROPgadget) > /dev/null && echo "OK" || echo "MISSING"
echo -n "Patient:    "; test -f targets/patient_zero && echo "OK" || echo "MISSING"
echo -n "Odin FFI:   "; test -f implants/libhook_test.so && echo "OK" || echo "NOT BUILT"

echo ""
echo "[*] Testing Odin FFI..."
cd ~/vivisect
luajit hooks/test_odin_ffi.lua 2>&1 | tail -1

echo ""
echo "[*] Testing patient_zero..."
targets/patient_zero VIVISECT 2>&1 | grep -q "ACCESS GRANTED" && echo "[+] Patient responds correctly" || echo "[-] Patient authentication broken"

echo ""
echo "[+] If all OK, type: chapter 2"
