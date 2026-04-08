-- lib/rop.lua - Fixed file reading

local M = {}

local patterns = {
    pop_rdi_ret = "\x5f\xc3",
    pop_rsi_ret = "\x5e\xc3",
    pop_rdx_ret = "\x5a\xc3",
    syscall_ret = "\x0f\x05\xc3",
    ret = "\xc3",
}

function M.find_gadgets(binary_path)
    local f = io.open(binary_path, "rb")
    if not f then
        print("[-] Cannot open binary: " .. binary_path)
        return {}
    end
    
    local data = f:read("*a")
    f:close()
    
    if not data or #data == 0 then
        print("[-] Binary is empty or unreadable")
        return {}
    end
    
    local gadgets = {}
    local base_addr = 0x400000
    
    for name, pattern in pairs(patterns) do
        local pos = 1
        while true do
            local start = data:find(pattern, pos, true)
            if not start then break end
            
            local addr = base_addr + start - 1
            table.insert(gadgets, {
                name = name,
                address = addr,
                bytes = pattern
            })
            
            pos = start + 1
        end
    end
    
    return gadgets
end

function M.print_gadgets(gadgets)
    if #gadgets == 0 then
        print("[-] No gadgets found")
        return
    end
    
    print(string.format("\n[+] Found %d ROP gadgets:", #gadgets))
    for _, g in ipairs(gadgets) do
        local hex = {}
        for i = 1, #g.bytes do
            table.insert(hex, string.format("%02X", g.bytes:byte(i)))
        end
        print(string.format("    0x%08X  %-15s [%s]", g.address, g.name, table.concat(hex, " ")))
    end
end

return M
