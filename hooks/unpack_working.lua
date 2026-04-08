#!/usr/bin/env luajit
-- unpack_working.lua - ACTUALLY WORKS

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

print("[*] Launching: " .. binary)

local pid = ffi.C.fork()

if pid == 0 then
    ffi.C.sleep(1)
    ffi.C.execl(binary, binary, nil)
    os.exit(1)
end

print(string.format("[+] PID: %d", pid))
ffi.C.sleep(1)

-- Attach immediately
print("[*] Attaching...")
ffi.C.ptrace(PTRACE_ATTACH, pid, nil, nil)
ffi.C.waitpid(pid, nil, 0)

-- Single-step until we're in user code (not libc)
print("[*] Stepping until unpacked...")
for i = 1, 50000 do
    local regs = ffi.new("user_regs_struct")
    ffi.C.ptrace(PTRACE_GETREGS, pid, nil, regs)
    
    -- Check if RIP is in user space (0x400000 range)
    if regs.rip >= 0x400000 and regs.rip < 0x600000 then
        print(string.format("[+] Found user code at 0x%X (step %d)", 
            tonumber(regs.rip), i))
        
        -- NOW dump memory while paused
        print("[*] Dumping memory NOW...")
        
        local dump = io.open("final_dump.bin", "wb")
        local maps = io.open(string.format("/proc/%d/maps", pid), "r")
        
        if maps then
            for line in maps:lines() do
                local addr_start, addr_end = line:match("(%x+)%-(%x+)")
                if addr_start then
                    addr_start = tonumber(addr_start, 16)
                    addr_end = tonumber(addr_end, 16)
                    local size = addr_end - addr_start
                    
                    -- Read memory using ptrace
                    for offset = 0, size-1, 8 do
                        local word = ffi.C.ptrace(PTRACE_PEEKDATA, pid, 
                            ffi.cast("void*", addr_start + offset), nil)
                        
                        if word ~= -1 then
                            for j = 0, 7 do
                                local byte = bit.band(bit.rshift(tonumber(word), j*8), 0xFF)
                                dump:write(string.char(byte))
                            end
                        end
                    end
                end
            end
            maps:close()
        end
        
        dump:close()
        print("[+] Dumped to final_dump.bin")
        break
    end
    
    -- Single step
    ffi.C.ptrace(PTRACE_SINGLESTEP, pid, nil, nil)
    ffi.C.waitpid(pid, nil, 0)
    
    if i % 5000 == 0 then
        local regs = ffi.new("user_regs_struct")
        ffi.C.ptrace(PTRACE_GETREGS, pid, nil, regs)
        print(string.format("  [%d] RIP: 0x%X", i, tonumber(regs.rip)))
    end
end

-- Cleanup
ffi.C.ptrace(PTRACE_DETACH, pid, nil, nil)
ffi.C.kill(pid, 9)

print("\n[+] Check: strings final_dump.bin | grep FLAG")
