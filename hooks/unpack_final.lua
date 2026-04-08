#!/usr/bin/env luajit
-- unpack_final.lua - Wait for the REAL entry point

local ffi = require("ffi")

ffi.cdef[[
    int fork(void);
    int execl(const char *path, const char *arg0, ...);
    unsigned int sleep(unsigned int);
    long ptrace(int request, int pid, void *addr, void *data);
    int waitpid(int pid, int *status, int options);
    int kill(int pid, int sig);
    
    typedef struct {
        uint64_t r15, r14, r13, r12, rbp, rbx, r11, r10;
        uint64_t r9, r8, rax, rcx, rdx, rsi, rdi, orig_rax;
        uint64_t rip, cs, eflags, rsp, ss;
        uint64_t fs_base, gs_base, ds, es, fs, gs;
    } user_regs_struct;
]]

local PTRACE_ATTACH = 16
local PTRACE_DETACH = 17
local PTRACE_PEEKDATA = 2
local PTRACE_GETREGS = 12
local PTRACE_SINGLESTEP = 9

local binary = arg[1] or "targets/definitely_packable_packed"

print("╔══════════════════════════════════════════╗")
print("║  UPX Unpacker - Final Working Version   ║")
print("╚══════════════════════════════════════════╝\n")

print("[*] Target: " .. binary)

local pid = ffi.C.fork()

if pid == 0 then
    ffi.C.sleep(1)
    ffi.C.execl(binary, binary, nil)
    os.exit(1)
end

print(string.format("[+] PID: %d", pid))
ffi.C.sleep(1)

print("[*] Attaching...")
ffi.C.ptrace(PTRACE_ATTACH, pid, nil, nil)
ffi.C.waitpid(pid, nil, 0)

-- Track where we've been
local prev_rip = 0
local stable_count = 0
local in_user_code = false

print("[*] Waiting for UPX to unpack and jump to OEP...")

for i = 1, 100000 do
    local regs = ffi.new("user_regs_struct")
    ffi.C.ptrace(PTRACE_GETREGS, pid, nil, regs)
    local rip = tonumber(regs.rip)
    
    -- Detect when RIP CHANGES to a new region
    if rip >= 0x400000 and rip < 0x600000 then
        if not in_user_code then
            in_user_code = true
            print(string.format("[*] Entered user code region at 0x%X", rip))
        end
        
        -- Check if RIP is STABLE (not changing much)
        if math.abs(rip - prev_rip) < 0x1000 then
            stable_count = stable_count + 1
            
            -- If it's been stable for 1000 steps, it's likely unpacked
            if stable_count > 1000 then
                print(string.format("[+] Code stabilized at 0x%X (step %d)", rip, i))
                print("[+] Likely reached Original Entry Point!")
                
                -- Dump memory NOW
                print("\n[*] Dumping unpacked memory...")
                
                local dump = io.open("oep_dump.bin", "wb")
                local total = 0
                
                local maps = io.open(string.format("/proc/%d/maps", pid), "r")
                if maps then
                    for line in maps:lines() do
                        local addr_start, addr_end, perms = line:match("(%x+)%-(%x+)%s+([rwxp-]+)")
                        if addr_start and (perms:match("r") or perms:match("x")) then
                            addr_start = tonumber(addr_start, 16)
                            addr_end = tonumber(addr_end, 16)
                            local size = addr_end - addr_start
                            
                            print(string.format("  Region: 0x%X-0x%X (%d KB) %s", 
                                addr_start, addr_end, size/1024, perms))
                            
                            for offset = 0, size-1, 8 do
                                local word = ffi.C.ptrace(PTRACE_PEEKDATA, pid, 
                                    ffi.cast("void*", addr_start + offset), nil)
                                
                                if word ~= -1 then
                                    for j = 0, 7 do
                                        local byte = bit.band(bit.rshift(tonumber(word), j*8), 0xFF)
                                        dump:write(string.char(byte))
                                        total = total + 1
                                    end
                                end
                            end
                        end
                    end
                    maps:close()
                end
                
                dump:close()
                print(string.format("\n[+] Dumped %d KB to oep_dump.bin", total/1024))
                break
            end
        else
            stable_count = 0
        end
    end
    
    prev_rip = rip
    
    -- Progress
    if i % 10000 == 0 then
        print(string.format("  [%d] RIP: 0x%X", i, rip))
    end
    
    -- Single step
    ffi.C.ptrace(PTRACE_SINGLESTEP, pid, nil, nil)
    ffi.C.waitpid(pid, nil, 0)
end

ffi.C.ptrace(PTRACE_DETACH, pid, nil, nil)
ffi.C.kill(pid, 9)

print("\n╔══════════════════════════════════════════╗")
print("║  Unpacking Complete                      ║")
print("╚══════════════════════════════════════════╝")
print("\nCheck for strings:")
print("  strings oep_dump.bin | grep -i flag")
print("  strings oep_dump.bin | less")
