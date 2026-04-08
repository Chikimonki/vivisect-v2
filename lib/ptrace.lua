-- lib/ptrace.lua
-- Clean ptrace wrapper for LuaJIT

local ffi = require("ffi")

ffi.cdef[[
    long ptrace(int request, int pid, void *addr, void *data);
    int waitpid(int pid, int *status, int options);
    
    typedef struct {
        uint64_t r15, r14, r13, r12, rbp, rbx, r11, r10;
        uint64_t r9, r8, rax, rcx, rdx, rsi, rdi, orig_rax;
        uint64_t rip, cs, eflags, rsp, ss;
        uint64_t fs_base, gs_base, ds, es, fs, gs;
    } user_regs_struct;
]]

local M = {}

-- Constants
M.PTRACE_ATTACH      = 16
M.PTRACE_DETACH      = 17
M.PTRACE_PEEKDATA    = 2
M.PTRACE_POKEDATA    = 5
M.PTRACE_GETREGS     = 12
M.PTRACE_SETREGS     = 13
M.PTRACE_CONT        = 7
M.PTRACE_SINGLESTEP  = 9

function M.attach(pid)
    local ret = ffi.C.ptrace(M.PTRACE_ATTACH, pid, nil, nil)
    if ret ~= 0 then
        return nil, "attach failed"
    end
    
    local status = ffi.new("int[1]")
    ffi.C.waitpid(pid, status, 0)
    return true
end

function M.detach(pid)
    ffi.C.ptrace(M.PTRACE_DETACH, pid, nil, nil)
    return true
end

function M.read_memory(pid, addr, size)
    local bytes = {}
    for i = 0, size - 1, 8 do
        local word = ffi.C.ptrace(M.PTRACE_PEEKDATA, pid, 
            ffi.cast("void*", addr + i), nil)
        
        for j = 0, math.min(7, size - i - 1) do
            local byte = bit.band(bit.rshift(tonumber(word), j * 8), 0xFF)
            table.insert(bytes, byte)
        end
    end
    return bytes
end

function M.write_memory(pid, addr, bytes)
    for i = 1, #bytes, 8 do
        local word = 0
        for j = 0, 7 do
            if bytes[i + j] then
                word = word + bit.lshift(bytes[i + j], j * 8)
            end
        end
        ffi.C.ptrace(M.PTRACE_POKEDATA, pid, 
            ffi.cast("void*", addr + i - 1), ffi.cast("void*", word))
    end
    return true
end

function M.get_registers(pid)
    local regs = ffi.new("user_regs_struct")
    ffi.C.ptrace(M.PTRACE_GETREGS, pid, nil, regs)
    
    return {
        rip = tonumber(regs.rip),
        rsp = tonumber(regs.rsp),
        rbp = tonumber(regs.rbp),
        rax = tonumber(regs.rax),
        rbx = tonumber(regs.rbx),
        rcx = tonumber(regs.rcx),
        rdx = tonumber(regs.rdx),
        rsi = tonumber(regs.rsi),
        rdi = tonumber(regs.rdi),
        r8  = tonumber(regs.r8),
        r9  = tonumber(regs.r9),
        r10 = tonumber(regs.r10),
        r11 = tonumber(regs.r11),
        r12 = tonumber(regs.r12),
        r13 = tonumber(regs.r13),
        r14 = tonumber(regs.r14),
        r15 = tonumber(regs.r15),
        eflags = tonumber(regs.eflags)
    }
end

function M.set_register(pid, reg_name, value)
    local regs = ffi.new("user_regs_struct")
    ffi.C.ptrace(M.PTRACE_GETREGS, pid, nil, regs)
    
    regs[reg_name] = value
    
    ffi.C.ptrace(M.PTRACE_SETREGS, pid, nil, regs)
    return true
end

function M.single_step(pid)
    ffi.C.ptrace(M.PTRACE_SINGLESTEP, pid, nil, nil)
    local status = ffi.new("int[1]")
    ffi.C.waitpid(pid, status, 0)
    return true
end

function M.continue_execution(pid)
    ffi.C.ptrace(M.PTRACE_CONT, pid, nil, nil)
    local status = ffi.new("int[1]")
    ffi.C.waitpid(pid, status, 0)
    return true
end

return M
