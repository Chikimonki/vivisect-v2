#!/usr/bin/env luajit
-- unpack.lua - Automatic unpacker

package.path = package.path .. ";./lib/?.lua"

local ptrace = require("ptrace")
local packer_detect = require("packer_detect")

local Unpacker = {}
Unpacker.__index = Unpacker

function Unpacker.new(binary_path)
    local self = setmetatable({}, Unpacker)
    self.binary_path = binary_path
    self.pid = nil
    self.oep = nil
    return self
end

function Unpacker:detect()
    local packer = packer_detect.detect_packer(self.binary_path)
    
    if packer then
        print(string.format("[+] Detected packer: %s", packer))
        return packer
    else
        print("[-] Binary does not appear to be packed")
        return nil
    end
end

function Unpacker:launch_and_attach()
    print("[*] Launching packed binary...")
    
    -- Fork and exec
    local ffi = require("ffi")
    ffi.cdef[[
        int fork(void);
        int execl(const char *path, const char *arg0, ...);
        unsigned int sleep(unsigned int seconds);
    ]]
    
    local pid = ffi.C.fork()
    
    if pid == 0 then
        -- Child: wait a moment for parent to attach
        ffi.C.sleep(1)
        ffi.C.execl(self.binary_path, self.binary_path, nil)
        os.exit(1)
    end
    
    self.pid = pid
    print(string.format("[+] Launched PID %d", pid))
    
    -- Give it time to start
    ffi.C.sleep(1)
    
    -- Attach
    ptrace.attach(pid)
    print("[+] Attached")
end

function Unpacker:wait_for_unpack()
    print("[*] Waiting for unpacker to finish...")
    
    -- Strategy: single-step and watch for:
    -- 1. Large memcpy/mmap calls
    -- 2. Change in code region permissions
    -- 3. Jump to previously non-executable memory
    
    local steps = 0
    local max_steps = 10000
    
    while steps < max_steps do
        local regs = ptrace.get_registers(self.pid)
        
        -- Check if we're in a new memory region
        local maps = io.open(string.format("/proc/%d/maps", self.pid), "r")
        if maps then
            local in_original = false
            for line in maps:lines() do
                local addr_start = tonumber(line:match("^(%x+)"), 16)
                local addr_end = tonumber(line:match("^%x+-(%x+)"), 16)
                
                if regs.rip >= addr_start and regs.rip < addr_end then
                    if not line:match(self.binary_path) then
                        -- We're executing in a region NOT from the original binary
                        print(string.format("[+] OEP candidate: 0x%X", regs.rip))
                        print(string.format("    Region: %s", line))
                        self.oep = regs.rip
                        maps:close()
                        return true
                    end
                    in_original = true
                    break
                end
            end
            maps:close()
        end
        
        -- Progress indicator
        if steps % 1000 == 0 then
            print(string.format("[%d] RIP: 0x%X", steps, regs.rip))
        end
        
        ptrace.single_step(self.pid)
        steps = steps + 1
    end
    
    print("[-] Max steps reached without finding OEP")
    return false
end

function Unpacker:dump_memory()
    if not self.oep then
        print("[-] No OEP found, dumping entire process memory")
    end
    
    print("[*] Dumping process memory...")
    
    local maps = io.open(string.format("/proc/%d/maps", self.pid), "r")
    if not maps then
        error("Cannot read memory maps")
    end
    
    local dump_file = io.open("unpacked_dump.bin", "wb")
    local regions_dumped = 0
    
    for line in maps:lines() do
        local addr_start, addr_end, perms = line:match("(%x+)%-(%x+)%s+([rwxp-]+)")
        
        if addr_start and perms:match("r") then
            addr_start = tonumber(addr_start, 16)
            addr_end = tonumber(addr_end, 16)
            local size = addr_end - addr_start
            
            print(string.format("[*] Dumping: 0x%X - 0x%X (%d bytes) %s", 
                addr_start, addr_end, size, perms))
            
            -- Read memory in chunks
            local chunk_size = 4096
            for offset = 0, size - 1, chunk_size do
                local read_size = math.min(chunk_size, size - offset)
                local bytes = ptrace.read_memory(self.pid, addr_start + offset, read_size)
                
                if bytes and #bytes > 0 then
                    for _, byte in ipairs(bytes) do
                        dump_file:write(string.char(byte))
                    end
                end
            end
            
            regions_dumped = regions_dumped + 1
        end
    end
    
    maps:close()
    dump_file:close()
    
    print(string.format("[+] Dumped %d regions to unpacked_dump.bin", regions_dumped))
end

function Unpacker:rebuild_elf()
    print("[*] Rebuilding clean ELF...")
    
    -- This is simplified - real ELF rebuilding is complex
    -- For now, we just mark the dump location
    
    print("[*] Unpacked code is at OEP: 0x" .. string.format("%X", self.oep or 0))
    print("[*] Use 'objcopy' or custom ELF builder to create bootable binary")
    print("[*] For UPX: just use 'upx -d <binary>' as verification")
end

-- Main
local binary_path = arg[1]

if not binary_path then
    print("Usage: sudo luajit unpack.lua <packed_binary>")
    print("\nExample:")
    print("  sudo luajit unpack.lua packed_malware")
    os.exit(1)
end

local unpacker = Unpacker.new(binary_path)

print("╔══════════════════════════════════════════╗")
print("║       Automated Unpacker v1.0            ║")
print("╚══════════════════════════════════════════╝\n")

local packer = unpacker:detect()

if packer then
    unpacker:launch_and_attach()
    
    if unpacker:wait_for_unpack() then
        print("\n[+] Unpacking detected!")
        unpacker:dump_memory()
        unpacker:rebuild_elf()
    else
        print("\n[-] Could not detect unpacking")
        print("[*] Dumping memory anyway (might contain unpacked code)")
        unpacker:dump_memory()
    end
    
    ptrace.detach(unpacker.pid)
else
    print("[*] Binary is not packed (or uses unknown packer)")
    print("[*] No unpacking needed")
end
