#!/usr/bin/env luajit
-- inline_hook.lua
-- Overwrite function bytes with jump to our trampoline

local ffi = require("ffi")

ffi.cdef[[
    long ptrace(int request, int pid, void *addr, void *data);
    int waitpid(int pid, int *status, int options);
    void *mmap(void *addr, size_t length, int prot, int flags, int fd, long offset);
    int mprotect(void *addr, size_t len, int prot);
    
    static const int PROT_READ = 1;
    static const int PROT_WRITE = 2;
    static const int PROT_EXEC = 4;
    static const int MAP_PRIVATE = 2;
    static const int MAP_ANONYMOUS = 0x20;
]]

local PTRACE_ATTACH = 16
local PTRACE_DETACH = 17
local PTRACE_PEEKDATA = 2
local PTRACE_POKEDATA = 5

local function attach(pid)
    print(string.format("[*] Attaching to PID %d", pid))
    if ffi.C.ptrace(PTRACE_ATTACH, pid, nil, nil) ~= 0 then
        error("ptrace ATTACH failed")
    end
    local status = ffi.new("int[1]")
    ffi.C.waitpid(pid, status, 0)
    print("[+] Attached")
end

local function detach(pid)
    ffi.C.ptrace(PTRACE_DETACH, pid, nil, nil)
    print("[+] Detached")
end

local function read_bytes(pid, addr, count)
    local bytes = {}
    for i = 0, count - 1, 8 do
        local word = ffi.C.ptrace(PTRACE_PEEKDATA, pid, 
            ffi.cast("void*", addr + i), nil)
        
        -- Extract bytes from word
        for j = 0, math.min(7, count - i - 1) do
            local byte = bit.band(bit.rshift(tonumber(word), j * 8), 0xFF)
            table.insert(bytes, byte)
        end
    end
    return bytes
end

local function write_bytes(pid, addr, bytes)
    -- Write 8 bytes at a time (ptrace limitation)
    for i = 1, #bytes, 8 do
        local word = 0
        for j = 0, 7 do
            if bytes[i + j] then
                word = word + bit.lshift(bytes[i + j], j * 8)
            end
        end
        ffi.C.ptrace(PTRACE_POKEDATA, pid, 
            ffi.cast("void*", addr + i - 1), ffi.cast("void*", word))
    end
end

-- Main
local pid = tonumber(arg[1])
local target_addr = tonumber(arg[2], 16)
local hook_addr = tonumber(arg[3], 16)

if not pid or not target_addr or not hook_addr then
    print("Usage: sudo luajit inline_hook.lua <pid> <strcmp_addr> <trampoline_addr>")
    os.exit(1)
end

print(string.format("[*] Target PID: %d", pid))
print(string.format("[*] strcmp at: 0x%X", target_addr))
print(string.format("[*] Trampoline at: 0x%X", hook_addr))

attach(pid)

-- Read original bytes
print("[*] Reading original bytes...")
local original = read_bytes(pid, target_addr, 12)
print("[+] Original bytes: " .. table.concat(
    (function()
        local hex = {}
        for _, b in ipairs(original) do
            table.insert(hex, string.format("%02X", b))
        end
        return hex
    end)(), " "))

-- Calculate relative jump offset
local offset = hook_addr - (target_addr + 5)
print(string.format("[*] Jump offset: 0x%X", offset))

-- Build jump instruction: E9 <offset>
local jump_bytes = {
    0xE9,  -- JMP rel32
    bit.band(offset, 0xFF),
    bit.band(bit.rshift(offset, 8), 0xFF),
    bit.band(bit.rshift(offset, 16), 0xFF),
    bit.band(bit.rshift(offset, 24), 0xFF),
    0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90  -- NOPs
}

print("[+] Injecting jump...")
write_bytes(pid, target_addr, jump_bytes)

-- Verify
local verify = read_bytes(pid, target_addr, 12)
print("[+] Patched bytes: " .. table.concat(
    (function()
        local hex = {}
        for _, b in ipairs(verify) do
            table.insert(hex, string.format("%02X", b))
        end
        return hex
    end)(), " "))

detach(pid)
print("[+] Inline hook installed. Press Enter in target.")