#!/usr/bin/env luajit
-- auto_pwn_standalone.lua - Standalone Neural ROP Engine

local ffi = require("ffi")

ffi.cdef[[
    typedef struct {
        unsigned char e_ident[16];
        uint16_t e_type;
        uint16_t e_machine;
        uint32_t e_version;
        uint64_t e_entry;
        uint64_t e_phoff;
        uint64_t e_shoff;
    } Elf64_Ehdr;
]]

local function read_elf_header(path)
    local f = io.open(path, "rb")
    if not f then return nil, "Cannot open file" end
    
    local header_data = f:read(64)
    f:close()
    
    if not header_data or #header_data < 64 then
        return nil, "Invalid ELF"
    end
    
    local header = ffi.cast("Elf64_Ehdr*", header_data)
    
    -- Check ELF magic
    if header.e_ident[0] ~= 0x7f or 
       header.e_ident[1] ~= string.byte('E') or
       header.e_ident[2] ~= string.byte('L') or
       header.e_ident[3] ~= string.byte('F') then
        return nil, "Not an ELF file"
    end
    
    return header
end

local function find_gadgets(path)
    local f = io.open(path, "rb")
    if not f then return {} end
    
    local data = f:read("*a")
    f:close()
    
    local gadgets = {}
    
    -- ROP gadget patterns (x86-64)
    local patterns = {
        {name = "pop rdi; ret", bytes = "\x5f\xc3"},
        {name = "pop rsi; ret", bytes = "\x5e\xc3"},
        {name = "pop rdx; ret", bytes = "\x5a\xc3"},
        {name = "pop rax; ret", bytes = "\x58\xc3"},
        {name = "pop rbx; ret", bytes = "\x5b\xc3"},
        {name = "pop rcx; ret", bytes = "\x59\xc3"},
        {name = "syscall; ret", bytes = "\x0f\x05\xc3"},
        {name = "int 0x80; ret", bytes = "\xcd\x80\xc3"},
        {name = "ret", bytes = "\xc3"},
    }
    
    for _, pattern in ipairs(patterns) do
        local offset = 1
        while true do
            local pos = data:find(pattern.bytes, offset, true)
            if not pos then break end
            
            table.insert(gadgets, {
                name = pattern.name,
                offset = pos - 1,
                address = string.format("0x%x", pos - 1)
            })
            
            offset = pos + 1
        end
    end
    
    return gadgets
end

local function check_protections(path)
    local output = io.popen("readelf -l " .. path .. " 2>&1"):read("*a")
    
    local nx = output:match("GNU_STACK") and not output:match("RWE")
    local pie = output:match("DYN") ~= nil
    
    local symbols_out = io.popen("readelf -s " .. path .. " 2>&1"):read("*a")
    local canary = symbols_out:match("stack_chk") ~= nil
    
    return {
        nx = nx,
        pie = pie,
        canary = canary,
        relro = output:match("GNU_RELRO") ~= nil
    }
end

local function auto_pwn(binary_path)
    print([[
╔══════════════════════════════════════════╗
║   VIVISECT NEURAL ROP ENGINE v2.0       ║
╚══════════════════════════════════════════╝
]])
    
    print("\n[*] Target: " .. binary_path)
    
    -- Read ELF header
    local header, err = read_elf_header(binary_path)
    if not header then
        print("[-] " .. err)
        return
    end
    
    print("[+] Valid ELF64 binary")
    print(string.format("[*] Entry point: 0x%x", tonumber(header.e_entry)))
    
    -- Check protections
    print("\n[*] Security Analysis:")
    local protections = check_protections(binary_path)
    
    print(string.format("  NX:     %s", protections.nx and "✓ Enabled" or "✗ Disabled"))
    print(string.format("  PIE:    %s", protections.pie and "✓ Enabled" or "✗ Disabled"))
    print(string.format("  Canary: %s", protections.canary and "✓ Enabled" or "✗ Disabled"))
    print(string.format("  RELRO:  %s", protections.relro and "✓ Enabled" or "✗ Disabled"))
    
    -- Find gadgets
    print("\n[*] Searching for ROP gadgets...")
    local gadgets = find_gadgets(binary_path)
    
    if #gadgets == 0 then
        print("[-] No gadgets found")
        return
    end
    
    print(string.format("[+] Found %d total gadgets\n", #gadgets))
    
    -- Group and count by type
    local by_type = {}
    for _, g in ipairs(gadgets) do
        by_type[g.name] = by_type[g.name] or {}
        table.insert(by_type[g.name], g)
    end
    
    print("[*] Gadget Summary:")
    for name, list in pairs(by_type) do
        print(string.format("  %-20s %d found", name .. ":", #list))
        
        -- Show first 3 addresses
        local shown = 0
        for _, g in ipairs(list) do
            if shown >= 3 then break end
            print(string.format("    → %s", g.address))
            shown = shown + 1
        end
    end
    
    -- Generate exploit strategy
    print("\n[*] Exploit Strategy Recommendation:")
    
    if not protections.nx and not protections.pie then
        print("  → Shellcode injection (NX disabled, static addresses)")
        print("  → Classic buffer overflow → shellcode")
    elseif protections.nx and not protections.pie then
        print("  → ROP chain required (NX enabled)")
        print("  → Static addresses available")
        print("  → Strategy: ret2libc or ret2syscall")
    elseif protections.nx and protections.pie then
        print("  → Advanced ROP + info leak required")
        print("  → Need to defeat ASLR first")
        print("  → Consider format string or use-after-free for leak")
    end
    
    if protections.canary then
        print("  ⚠ Stack canary detected - need canary leak or bypass")
    end
    
    print("\n[+] Analysis complete\n")
end

-- Main
local binary = arg[1]
if not binary then
    print("Usage: luajit auto_pwn_standalone.lua <binary>")
    os.exit(1)
end

auto_pwn(binary)
