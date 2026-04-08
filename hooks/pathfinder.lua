#!/usr/bin/env luajit
-- pathfinder.lua
-- Automatically find inputs that reach target addresses

package.path = package.path .. ";./lib/?.lua"

local ptrace = require("ptrace")
local disasm = require("disasm")
local symbolic = require("symbolic")

local function find_path(pid, target_name)
    print(string.format("[*] Finding path to: %s", target_name))
    
    ptrace.attach(pid)
    
    local explorer = symbolic.PathExplorer.new()
    local max_steps = 1000
    local step = 0
    
    while step < max_steps do
        local regs = ptrace.get_registers(pid)
        local bytes = ptrace.read_memory(pid, regs.rip, 16)
        local insns = disasm.disassemble(bytes, regs.rip, 1)
        
        if not insns or #insns == 0 then break end
        
        local insn = insns[1]
        
        -- Detect branches and fork exploration
        if insn.mnemonic:match("^j") then
            -- Extract comparison (simplified)
            local constraint = string.format("input == 0x%X", regs.rax)
            explorer:explore_branch(insn.address, constraint)
            
            print(string.format("[FORK] 0x%X: %s (constraint: %s)", 
                insn.address, insn.mnemonic, constraint))
        end
        
        -- Check if we reached target
        -- (In real implementation, compare against symbol table)
        
        ptrace.single_step(pid)
        step = step + 1
    end
    
    ptrace.detach(pid)
    
    print("[+] Exploration complete")
    print(string.format("[*] Explored %d states", #explorer.states))
end

-- Main
local pid = tonumber(arg[1])
local target = arg[2] or "win"

if not pid then
    print("Usage: sudo luajit pathfinder.lua <pid> [target_function]")
    os.exit(1)
end

find_path(pid, target)
