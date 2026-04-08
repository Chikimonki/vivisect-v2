#!/usr/bin/env luajit
-- unpack_patient.lua - Give UPX time to finish

local ffi = require("ffi")
local ptrace = require("lib.ptrace")

ffi.cdef[[
    int fork(void);
    int execl(const char *path, const char *arg0, ...);
    unsigned int sleep(unsigned int);
    int kill(int pid, int sig);
]]

local binary = arg[1] or "targets/definitely_packable_packed"

print("[*] Launching " .. binary)

local pid = ffi.C.fork()

if pid == 0 then
    ffi.C.sleep(1)
    ffi.C.execl(binary, binary, nil)
    os.exit(1)
end

print(string.format("[+] PID: %d", pid))
print("[*] Waiting 10 seconds for UPX to unpack...")

-- DON'T attach yet - let it run freely
ffi.C.sleep(10)

-- NOW attach and dump
print("[*] Attaching...")
ptrace.attach(pid)

print("[*] Dumping memory...")
local dump = io.open("patient_dump.bin", "wb")
local total = 0

local maps = io.open(string.format("/proc/%d/maps", pid), "r")
for line in maps:lines() do
    local addr_start, addr_end, perms = line:match("(%x+)%-(%x+)%s+([rwxp-]+)")
    if addr_start and perms:match("r") then
        addr_start = tonumber(addr_start, 16)
        addr_end = tonumber(addr_end, 16)
        local size = addr_end - addr_start
        
        for offset = 0, size-1, 4096 do
            local bytes = ptrace.read_memory(pid, addr_start + offset, 
                math.min(4096, size - offset))
            if bytes then
                for _, b in ipairs(bytes) do
                    dump:write(string.char(b))
                end
                total = total + #bytes
            end
        end
    end
end

maps:close()
dump:close()

print(string.format("[+] Dumped %d KB", total / 1024))

ptrace.detach(pid)
ffi.C.kill(pid, 9)

print("\n[+] Check: strings patient_dump.bin | grep FLAG")
