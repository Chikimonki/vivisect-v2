#!/usr/bin/env luajit
-- debugger.lua - Full debugger in LuaJIT
-- Single-step, breakpoints, memory inspection, disassembly

package.path = package.path .. ";./lib/?.lua"

local ptrace = require("ptrace")
local disasm = require("disasm")

local Debugger = {}
Debugger.__index = Debugger

function Debugger.new(pid)
    local self = setmetatable({}, Debugger)
    self.pid = pid
    self.attached = false
    self.breakpoints = {}
    return self
end

function Debugger:attach()
    print(string.format("[*] Attaching to PID %d...", self.pid))
    local ok, err = ptrace.attach(self.pid)
    if not ok then
        error("Attach failed: " .. tostring(err))
    end
    self.attached = true
    print("[+] Attached")
end

function Debugger:detach()
    if self.attached then
        ptrace.detach(self.pid)
        self.attached = false
        print("[+] Detached")
    end
end

function Debugger:show_registers()
    local regs = ptrace.get_registers(self.pid)
    
    print("\n┌─ Registers ─────────────────────────┐")
    print(string.format("│ RIP: 0x%016X             │", regs.rip))
    print(string.format("│ RSP: 0x%016X             │", regs.rsp))
    print(string.format("│ RBP: 0x%016X             │", regs.rbp))
    print(string.format("│ RAX: 0x%016X             │", regs.rax))
    print(string.format("│ RBX: 0x%016X             │", regs.rbx))
    print(string.format("│ RCX: 0x%016X             │", regs.rcx))
    print(string.format("│ RDX: 0x%016X             │", regs.rdx))
    print("└─────────────────────────────────────┘\n")
    
    return regs
end

function Debugger:disassemble_at_rip(count)
    local regs = ptrace.get_registers(self.pid)
    local bytes = ptrace.read_memory(self.pid, regs.rip, count or 64)
    
    local instructions = disasm.disassemble(bytes, regs.rip, 10)
    
    print("\n┌─ Disassembly ───────────────────────┐")
    for _, insn in ipairs(instructions) do
        local marker = (insn.address == regs.rip) and "→" or " "
        print(string.format("│ %s 0x%X: %s %s", 
            marker, insn.address, insn.mnemonic, insn.operands))
    end
    print("└─────────────────────────────────────┘\n")
end

function Debugger:step()
    ptrace.single_step(self.pid)
    print("[+] Single step")
end

function Debugger:continue_execution()
    ptrace.continue_execution(self.pid)
    print("[+] Continuing...")
end

function Debugger:read_memory(addr, size)
    local bytes = ptrace.read_memory(self.pid, addr, size)
    
    print(string.format("\n┌─ Memory at 0x%X ─────┐", addr))
    for i = 1, #bytes, 16 do
        local hex = {}
        local ascii = {}
        for j = i, math.min(i + 15, #bytes) do
            table.insert(hex, string.format("%02X", bytes[j]))
            local c = (bytes[j] >= 32 and bytes[j] < 127) and string.char(bytes[j]) or "."
            table.insert(ascii, c)
        end
        print(string.format("│ %04X: %-47s %s │", i - 1, table.concat(hex, " "), table.concat(ascii)))
    end
    print("└────────────────────────────────────────┘\n")
    
    return bytes
end

function Debugger:repl()
    print([[
╔══════════════════════════════════════════╗
║       LuaJIT Debugger v1.0               ║
║  s=step  c=cont  r=regs  d=disasm  q=quit║
╚══════════════════════════════════════════╝
]])
    
    while true do
        io.write("(vdb) ")
        local cmd = io.read()
        
        if cmd == "q" then
            break
        elseif cmd == "s" then
            self:step()
            self:show_registers()
            self:disassemble_at_rip()
        elseif cmd == "c" then
            self:continue_execution()
        elseif cmd == "r" then
            self:show_registers()
        elseif cmd == "d" then
            self:disassemble_at_rip()
        elseif cmd:match("^x ") then
            local addr = tonumber(cmd:match("^x (0x%x+)"), 16)
            if addr then
                self:read_memory(addr, 64)
            end
        else
            print("Unknown command. s=step c=cont r=regs d=disasm x <addr>=dump q=quit")
        end
    end
end

-- Main
local pid = tonumber(arg[1])
if not pid then
    print("Usage: sudo luajit debugger.lua <pid>")
    os.exit(1)
end

local dbg = Debugger.new(pid)
dbg:attach()
dbg:show_registers()
dbg:disassemble_at_rip()
dbg:repl()
dbg:detach()
