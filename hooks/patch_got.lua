#!/usr/bin/env luajit
-- patch_got.lua
-- Attach to a running process and patch its GOT

local ffi = require("ffi")

ffi.cdef[[
    long ptrace(int request, int pid, void *addr, void *data);
    int waitpid(int pid, int *status, int options);
    
    // ptrace requests
    static const int PTRACE_ATTACH = 16;
    static const int PTRACE_DETACH = 17;
    static const int PTRACE_PEEKDATA = 2;
    static const int PTRACE_POKEDATA = 5;
]]

local function attach(pid)
    print(string.format("[*] Attaching to PID %d...", pid))
    local ret = ffi.C.ptrace(ffi.C.PTRACE_ATTACH, pid, nil, nil)
    if ret ~= 0 then
        error("ptrace ATTACH failed")
    end
    
    local status = ffi.new("int[1]")
    ffi.C.waitpid(pid, status, 0)
    print("[+] Attached")
end

local function detach(pid)
    print("[*] Detaching...")
    ffi.C.ptrace(ffi.C.PTRACE_DETACH, pid, nil, nil)
    print("[+] Detached")
end

local function read_memory(pid, addr)
    local val = ffi.C.ptrace(ffi.C.PTRACE_PEEKDATA, pid, ffi.cast("void*", addr), nil)
    return tonumber(val)
end

local function write_memory(pid, addr, value)
    ffi.C.ptrace(ffi.C.PTRACE_POKEDATA, pid, 
        ffi.cast("void*", addr), ffi.cast("void*", value))
end

-- Main
local pid = tonumber(arg[1])
local got_addr = tonumber(arg[2], 16)
local new_addr = tonumber(arg[3], 16)

if not pid or not got_addr or not new_addr then
    print("Usage: luajit patch_got.lua <pid> <got_address> <new_function_address>")
    os.exit(1)
end

attach(pid)

local old_value = read_memory(pid, got_addr)
print(string.format("[*] GOT[0x%X] = 0x%X", got_addr, old_value))

write_memory(pid, got_addr, new_addr)
print(string.format("[+] GOT[0x%X] = 0x%X (patched!)", got_addr, new_addr))

local verify = read_memory(pid, got_addr)
print(string.format("[*] Verification: 0x%X", verify))

detach(pid)
print("[+] Process continues with hijacked function pointer")