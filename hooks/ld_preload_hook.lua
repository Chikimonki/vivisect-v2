#!/usr/bin/env luajit
-- ld_preload_hook.lua
-- Universal LD_PRELOAD hijacker

local ffi = require("ffi")

local target = arg[1] or "../targets/patient_zero"
local implant = arg[2] or "../implants/libstrcmp_hook.so"

-- Verify files exist
for _, path in ipairs({target, implant}) do
    local f = io.open(path, "r")
    if not f then
        print(string.format("[-] Missing: %s", path))
        os.exit(1)
    end
    f:close()
end

print(string.format("[+] Target:  %s", target))
print(string.format("[+] Implant: %s", implant))
print("[*] Launching with LD_PRELOAD...")

-- Launch with our library preloaded
local cmd = string.format("LD_PRELOAD=%s %s", implant, target)
print(string.format("[*] Command: %s", cmd))

-- Run it
local handle = io.popen(cmd .. " VIVISECT 2>&1")
local output = handle:read("*a")
handle:close()

print("\n[+] Output:")
print(output)

-- Try with wrong password too
print("[*] Testing with wrong password...")
handle = io.popen(cmd .. " WRONGPASSWORD 2>&1")
output = handle:read("*a")
handle:close()

print("\n[+] Wrong password output:")
print(output)

print("\n[+] strcmp() now belongs to us.")