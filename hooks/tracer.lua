#!/usr/bin/env luajit
-- tracer.lua - ROBUST VERSION
-- Handles partial instruction reads and invalid opcodes

package.path = package.path .. ";./lib/?.lua"

local ptrace = require("ptrace")
local disasm = require("disasm")

local Tracer = {}
Tracer.__index = Tracer

function Tracer.new(pid)
    local self = setmetatable({}, Tracer)
    self.pid = pid
    self.trace = {}
    self.branches = {}
    return self
end

function Tracer:attach()
    print(string.format("[*] Attaching to PID %d...", self.pid))
    ptrace.attach(self.pid)
    print("[+] Attached")
end

function Tracer:detach()
    ptrace.detach(self.pid)
    print("[+] Detached")
end

function Tracer:skip_to_main()
    print("[*] Skipping library code...")
    
    for i = 1, 200 do
        local regs = ptrace.get_registers(self.pid)
        
        -- User code is typically 0x400000-0x600000 range
        if regs.rip >= 0x400000 and regs.rip < 0x700000 then
            print(string.format("[+] Reached user code at 0x%X", regs.rip))
            return true
        end
        
        ptrace.single_step(self.pid)
    end
    
    return false
end

function Tracer:trace_execution(max_steps)
    local steps = 0
    
    print(string.format("[*] Starting trace (max %d steps)...", max_steps or 1000))
    
    while steps < (max_steps or 1000) do
        local regs = ptrace.get_registers(self.pid)
        
        if not regs or not regs.rip then
            print("[-] Failed to read registers")
            break
        end
        
        -- Read MORE bytes to avoid cutting instructions
        local bytes = ptrace.read_memory(self.pid, regs.rip, 64)
        
        if not bytes or #bytes == 0 then
            print(string.format("[-] Cannot read memory at 0x%X", regs.rip))
            break
        end
        
        -- Try to disassemble
        local insns, err = disasm.disassemble(bytes, regs.rip, 1)
        
        if not insns then
            print(string.format("[-] Disasm failed at 0x%X: %s", regs.rip, err or "unknown"))
            
            -- Dump the bytes for debugging
            local hex = {}
            for i = 1, math.min(16, #bytes) do
                table.insert(hex, string.format("%02X", bytes[i]))
            end
            print(string.format("    Bytes: %s", table.concat(hex, " ")))
            
            -- Try to continue anyway
            ptrace.single_step(self.pid)
            steps = steps + 1
            goto continue
        end
        
        local insn = insns[1]
        
        -- Record instruction
        table.insert(self.trace, {
            address = insn.address,
            mnemonic = insn.mnemonic,
            operands = insn.operands,
            rax = regs.rax,
            rip = regs.rip
        })
        
        -- Progress indicator
        if steps % 50 == 0 then
            print(string.format("[%04d] 0x%X: %s %s", 
                steps, insn.address, insn.mnemonic, insn.operands))
        end
        
        -- Detect conditional branches (NOT unconditional jmp)
        if insn.mnemonic:match("^j") and insn.mnemonic ~= "jmp" then
            table.insert(self.branches, {
                address = insn.address,
                instruction = insn.mnemonic .. " " .. insn.operands,
                rax = regs.rax,
                rflags = regs.eflags
            })
            
            print(string.format("[BRANCH] 0x%X: %s (rax=0x%X)", 
                insn.address, insn.mnemonic, regs.rax))
        end
        
        -- Detect function calls
        if insn.mnemonic == "call" then
            print(string.format("[CALL] 0x%X: %s", insn.address, insn.operands))
        end
        
        -- Detect interesting syscalls
        if insn.mnemonic == "syscall" then
            local syscall_name = ({
                [0] = "read", [1] = "write", [60] = "exit"
            })[regs.rax] or string.format("syscall_%d", regs.rax)
            
            print(string.format("[SYSCALL] 0x%X: %s", insn.address, syscall_name))
        end
        
        -- Check for program exit
        if insn.mnemonic == "ret" and regs.rbp == 0 then
            print("[*] Main function returned")
            break
        end
        
        -- Single step
        local ok = ptrace.single_step(self.pid)
        if not ok then
            print("[-] Process exited or single step failed")
            break
        end
        
        steps = steps + 1
        
        ::continue::
    end
    
    print(string.format("\n[+] Traced %d instructions, found %d branches", 
        #self.trace, #self.branches))
    
    return self.trace, self.branches
end

function Tracer:analyze_branches()
    if #self.branches == 0 then
        print("[-] No conditional branches found")
        print("    This could mean:")
        print("    - Program is very simple (no if statements)")
        print("    - Trace stopped before reaching comparisons")
        print("    - Password check is in a library function")
        return
    end
    
    print("\n┌─ Branch Analysis ────────────────────┐")
    
    for i, branch in ipairs(self.branches) do
        print(string.format("│ [%d] 0x%X: %s", i, branch.address, branch.instruction))
        print(string.format("│     RAX=0x%X  RFLAGS=0x%X", branch.rax, branch.rflags))
        
        -- Look back for the comparison
        for j = #self.trace, 1, -1 do
            local prev = self.trace[j]
            if prev.address < branch.address and 
               (prev.mnemonic == "cmp" or prev.mnemonic == "test") then
                print(string.format("│     Comparison: %s %s", 
                    prev.mnemonic, prev.operands))
                break
            end
        end
        print("│")
    end
    
    print("└──────────────────────────────────────┘\n")
end

function Tracer:extract_password_checks()
    print("\n┌─ Password Extraction ────────────────┐")
    
    local password = {}
    
    for _, entry in ipairs(self.trace) do
        -- Look for: cmp al, <immediate>
        if entry.mnemonic == "cmp" and entry.operands:match("al, 0x") then
            local byte_val = entry.operands:match("al, (0x%x+)")
            if byte_val then
                local char_code = tonumber(byte_val, 16)
                if char_code >= 32 and char_code < 127 then
                    table.insert(password, string.char(char_code))
                    print(string.format("│ Found: cmp al, %s → '%s'", 
                        byte_val, string.char(char_code)))
                end
            end
        end
    end
    
    if #password > 0 then
        print(string.format("│\n│ Reconstructed password: %s", 
            table.concat(password)))
    else
        print("│ No password pattern found")
    end
    
    print("└──────────────────────────────────────┘\n")
    
    return table.concat(password)
end

function Tracer:save_trace(filename)
    local f = io.open(filename, "w")
    if not f then return end
    
    f:write(string.format("# Execution Trace - %d instructions\n\n", #self.trace))
    
    for _, entry in ipairs(self.trace) do
        f:write(string.format("0x%08X: %-8s %s\n", 
            entry.address, entry.mnemonic, entry.operands))
    end
    
    f:close()
    print(string.format("[+] Full trace saved to %s", filename))
end

-- Main
local pid = tonumber(arg[1])
local max_steps = tonumber(arg[2]) or 1000

if not pid then
    print("Usage: sudo luajit tracer.lua <pid> [max_steps]")
    print("\nWorkflow:")
    print("  1. Terminal 1: ./targets/symbolic_challenge_waits TEST")
    print("  2. Note the PID")
    print("  3. Terminal 2: sudo luajit hooks/tracer.lua <PID>")
    print("  4. Terminal 1: Press Enter")
    os.exit(1)
end

local tracer = Tracer.new(pid)
tracer:attach()

if tracer:skip_to_main() then
    tracer:trace_execution(max_steps)
    tracer:analyze_branches()
    local password = tracer:extract_password_checks()
    
    if password ~= "" then
        print(string.format("\n[+] Try: ./targets/symbolic_challenge %s", password))
    end
    
    tracer:save_trace("trace.txt")
else
    print("[-] Could not reach user code")
end

tracer:detach()
