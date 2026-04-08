#!/usr/bin/env luajit
-- unpack_fast.lua - Just run it and dump

package.path = package.path .. ";./lib/?.lua"

local ffi = require("ffi")
local ptrace = require("ptrace")

ffi.cdef[[
    int fork(void);
    int execl(const char *path, const char *arg0, ...);
    unsigned int sleep(unsigned int);
    int kill(int pid, int sig);
]]

local binary = arg[1]
if not binary then
    print("Usage: sudo luajit unpack_fast.lua <binary>")
    os.exit(1)
end

print("[*] Launching " .. binary)

local pid = ffi.C.fork()

if pid == 0 then
    ffi.C.sleep(2)
    ffi.C.execl(binary, binary, nil)
    os.exit(1)
end

print(string.format("[+] PID: %d", pid))

-- Wait for it to start
ffi.C.sleep(2)

-- Attach
ptrace.attach(pid)
print("[+] Attached")

-- Continue execution (let UPX unpack naturally)
print("[*] Continuing execution for 3 seconds...")
ptrace.continue_execution(pid)
ffi.C.sleep(3)

-- It should be unpacked now, dump memory
print("[*] Dumping memory...")

local maps = io.open(string.format("/proc/%d/maps", pid), "r")
local dump = io.open("unpacked_fast.bin", "wb")

for line in maps:lines() do
    local addr_start, addr_end, perms = line:match("(%x+)%-(%x+)%s+([rwxp-]+)")
    
    if addr_start and perms:match("[wx]") then
        addr_start = tonumber(addr_start, 16)
        addr_end = tonumber(addr_end, 16)
        local size = addr_end - addr_start
        
        print(string.format("  0x%X (%d KB)", addr_start, size/1024))
        
        for offset = 0, size-1, 4096 do
            local bytes = ptrace.read_memory(pid, addr_start + offset, 
                math.min(4096, size - offset))
            if bytes then
                for _, b in ipairs(bytes) do
                    dump:write(string.char(b))
                end
            end
        end
    end
end

maps:close()
dump:close()

ptrace.detach(pid)
ffi.C.kill(pid, 9)

print("[+] Done! Check: strings unpacked_fast.bin | grep -i flag")
