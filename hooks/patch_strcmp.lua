#!/usr/bin/env luajit
local ffi = require("ffi")

ffi.cdef[[
    long ptrace(int request, int pid, void *addr, void *data);
    int waitpid(int pid, int *status, int options);
]]

local pid = tonumber(arg[1])
local addr = tonumber(arg[2], 16)

if not pid or not addr then
    print("Usage: sudo luajit patch_strcmp.lua <pid> <strcmp_address>")
    os.exit(1)
end

print(string.format("[*] Target PID: %d", pid))
print(string.format("[*] strcmp at: 0x%X", addr))

-- Attach
ffi.C.ptrace(16, pid, nil, nil)
ffi.C.waitpid(pid, nil, 0)
print("[+] Attached")

-- Read original 8 bytes
local original = ffi.C.ptrace(2, pid, ffi.cast("void*", addr), nil)
print(string.format("[*] Original bytes: 0x%016X", tonumber(original)))

-- Create shellcode: xor eax,eax ; ret ; nops
-- Bytes: 31 C0 C3 90 90 90 90 90
local shellcode = 0x9090909090C3C031ULL

print(string.format("[*] Writing shellcode: 0x%016X", tonumber(shellcode)))

-- Write it
ffi.C.ptrace(5, pid, ffi.cast("void*", addr), ffi.cast("void*", shellcode))

-- Verify
local verify = ffi.C.ptrace(2, pid, ffi.cast("void*", addr), nil)
print(string.format("[+] Patched bytes: 0x%016X", tonumber(verify)))

-- Detach
ffi.C.ptrace(17, pid, nil, nil)
print("[+] Detached - press Enter in target")
