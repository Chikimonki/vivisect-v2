-- lib/rop.lua - ROP gadget finder (pure LuaJIT)

local M = {}

-- x86-64 gadgets we care about
local patterns = {
    pop_rax_ret = "\x58\xc3",
    pop_rdi_ret = "\x5f\xc3",
    pop_rsi_ret = "\x5e\xc3",
    pop_rdx_ret = "\x5a\xc3",
    pop_rcx_ret = "\x59\xc3",
    syscall_ret = "\x0f\x05\xc3",
    ret = "\xc3",
}

function M.find_gadgets(binary_path)
    local f = io.open(binary_path, "rb")
    if not f then
        print("[-] Cannot open: " .. binary_path)
        return {}
    end
    
    local data = f:read("*a")
    f:close()
    
    local gadgets = {}
    local base_addr = 0x400000  -- Typical ELF base
    
    for name, pattern in pairs(patterns) do
        local pos = 1
        while true do
            local start = data:find(pattern, pos, true)
            if not start then break end
            
            local addr = base_addr + start - 1
            
            table.insert(gadgets, {
                name = name,
                address = addr,
                bytes = pattern,
                offset = start - 1
            })
            
            pos = start + 1
        end
    end
    
    -- Sort by address
    table.sort(gadgets, function(a, b) return a.address < b.address end)
    
    return gadgets
end

function M.print_gadgets(gadgets)
    print("\n┌─ Found ROP Gadgets ──────────────────┐")
    for _, g in ipairs(gadgets) do
        local hex_bytes = {}
        for i = 1, #g.bytes do
            table.insert(hex_bytes, string.format("%02X", g.bytes:byte(i)))
        end
        
        print(string.format("│ 0x%08X  %-20s [%s]", 
            g.address, g.name, table.concat(hex_bytes, " ")))
    end
    print(string.format("└──────────────────────────────────────┘"))
    print(string.format("Total: %d gadgets\n", #gadgets))
end

return M
