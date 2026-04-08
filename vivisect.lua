#!/usr/bin/env luajit
-- vivisect.lua - The One Tool

print([[
╔══════════════════════════════════════════╗
║              VIVISECT v1.0               ║
║    The Complete Binary Exploitation      ║
║           Framework (2026)               ║
╚══════════════════════════════════════════╝
]])

local cmd = arg[1]

if cmd == "hook" then
    dofile("./hooks/autohook.lua")
elseif cmd == "debug" then
    dofile("./hooks/debugger.lua")
elseif cmd == "unpack" then
    dofile("./hooks/unpack_final.lua")
elseif cmd == "rop" then
    dofile("./hooks/rop_builder.lua")
else
    print("Usage: ./vivisect.lua <command>")
    print("  hook    - Runtime hooking")
    print("  debug   - Full debugger")
    print("  unpack  - Binary unpacker")
    print("  rop     - ROP chain generator")
end
