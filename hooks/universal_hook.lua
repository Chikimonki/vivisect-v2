#!/usr/bin/env luajit
-- universal_hook.lua

local target = arg[1]
local implant = arg[2]
local password = arg[3] or "test"

if not target or not implant then
    print("Usage: luajit universal_hook.lua <binary> <hook.so> [password]")
    os.exit(1)
end

print(string.format("[*] Target:  %s", target))
print(string.format("[*] Implant: %s", implant))
print(string.format("[*] Running with: %s", password))

local cmd = string.format("LD_PRELOAD=%s %s %s 2>&1", implant, target, password)
local handle = io.popen(cmd)
local output = handle:read("*a")
handle:close()

print("\n[+] Output:")
print(output)