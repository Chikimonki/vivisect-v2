#!/usr/bin/env luajit
-- unpack_fixed.lua - Smarter OEP detection

package.path = package.path .. ";./lib/?.lua"

local ptrace = require("ptrace")
local packer_detect = require("packer_detect")
local ffi = require("ffi")

ffi.cdef[[
    int fork(void);
    int execl(const char *path, const char *arg0, ...);
    unsigned int sleep(unsigned int seconds);
    int kill(int pid, int sig);
]]

local function launch_binary(path)
    print("[*] Launching: " .. path)
    
    local pid = ffi.C.fork()
    
    if pid == 0 then
        -- Child: pause to let parent attach
        ffi.C.sleep(1)
        ffi.C.execl(path, path, nil)
        os.exit(1)
    end
    
    print(string.format("[+] PID: %d", pid))
    ffi.C.sleep(1)
    
    return pid
end

local function wait_for_oep_simple(pid)
    print("[*] Strategy: Let binary run, then dump when stable")
    
    -- Attach
    ptrace.attach(pid)
    
    -- Let it run for a few steps to unpack
    print("[*] Letting UPX unpack... (this takes ~30 seconds)")
    
    for i = 1, 50000 do
        if i % 5000 == 0 then
            local regs = ptrace.get_registers(pid)
            print(string.format("  [%d] RIP: 0x%X", i, regs.rip))
        end
        
        ptrace.single_step(pid)
    end
    
    local regs = ptrace.get_registers(pid)
    print(string.format("[+] Stopped at: 0x%X", regs.rip))
    
    return regs.rip
end

local function dump_memory(pid, output_file)
    print("[*] Dumping memory to " .. output_file)
    
    local maps_file = io.open(string.format("/proc/%d/maps", pid), "r")
    if not maps_file then
        print("[-] Cannot read memory maps")
        return false
    end
    
    local dump = io.open(output_file, "wb")
    local total_dumped = 0
    
    for line in maps_file:lines() do
        local addr_start, addr_end, perms, path = 
            line:match("(%x+)%-(%x+)%s+([rwxp-]+)%s+%x+%s+%x+:%x+%s+%d+%s*(.*)")
        
        if addr_start and perms:match("r") then
            addr_start = tonumber(addr_start, 16)
            addr_end = tonumber(addr_end, 16)
            local size = addr_end - addr_start
            
            -- Only dump executable or writable regions
            if perms:match("[wx]") then
                print(string.format("  Dumping: 0x%X-0x%X (%d KB) %s", 
                    addr_start, addr_end, size/1024, perms))
                
                -- Read in chunks
                for offset = 0, size - 1, 4096 do
                    local chunk_size = math.min(4096, size - offset)
                    local bytes = ptrace.read_memory(pid, addr_start + offset, chunk_size)
                    
                    if bytes then
                        for _, byte in ipairs(bytes) do
                            dump:write(string.char(byte))
                        end
                        total_dumped = total_dumped + #bytes
                    end
                end
            end
        end
    end
    
    maps_file:close()
    dump:close()
    
    print(string.format("[+] Dumped %d KB total", total_dumped / 1024))
    return true
end

-- Main
local binary = arg[1]

if not binary then
    print("Usage: sudo luajit unpack_fixed.lua <packed_binary>")
    os.exit(1)
end

print("╔══════════════════════════════════════════╗")
print("║     Auto-Unpacker v2.0 (Fixed)           ║")
print("╚══════════════════════════════════════════╝\n")

-- Detect packer
local packer = packer_detect.detect_packer(binary)
if packer then
    print(string.format("[+] Detected: %s\n", packer))
else
    print("[*] No packer detected (will dump anyway)\n")
end

-- Launch and attach
local pid = launch_binary(binary)

-- Wait for unpacking
local oep = wait_for_oep_simple(pid)

-- Dump memory
dump_memory(pid, "unpacked_dump.bin")

-- Cleanup
ptrace.detach(pid)
ffi.C.kill(pid, 9)  -- SIGKILL

print("\n[+] Done! Check unpacked_dump.bin")
print("[*] Search for strings:")
print("    strings unpacked_dump.bin | grep -i flag")
