-- lib/disasm.lua - FINAL FIXED VERSION
local ffi = require("ffi")

ffi.cdef[[
    typedef size_t cs_arch;
    typedef size_t cs_mode;
    typedef size_t csh;
    
    typedef struct cs_insn {
        unsigned int id;
        uint64_t address;
        uint16_t size;
        uint8_t bytes[16];
        char mnemonic[32];
        char op_str[160];
    } cs_insn;
    
    int cs_open(cs_arch arch, cs_mode mode, csh *handle);
    size_t cs_disasm(csh handle, const uint8_t *code, size_t code_size,
                     uint64_t address, size_t count, cs_insn **insn);
    void cs_free(cs_insn *insn, size_t count);
    int cs_close(csh *handle);
    const char *cs_strerror(int code);
]]

local M = {}

local CS_ARCH_X86 = 3
local CS_MODE_64  = 8

-- Load Capstone
local capstone
local ok = pcall(function()
    capstone = ffi.load("capstone")
end)

if not ok then
    ok = pcall(function()
        capstone = ffi.load("libcapstone.so.4")
    end)
end

if not ok then
    error("Capstone library not found. Install: sudo apt install libcapstone4")
end

function M.disassemble(bytes, address, count)
    -- Handle both Lua tables and C arrays
    local c_bytes
    local byte_count
    
    if type(bytes) == "table" then
        -- Convert Lua table to C array
        byte_count = #bytes
        c_bytes = ffi.new("uint8_t[?]", byte_count)
        for i = 1, byte_count do
            c_bytes[i - 1] = bytes[i]
        end
    elseif type(bytes) == "cdata" then
        -- Already a C array
        c_bytes = bytes
        byte_count = tonumber(ffi.sizeof(bytes))
    else
        return nil, "Invalid bytes type: " .. type(bytes)
    end
    
    local handle = ffi.new("csh[1]")
    
    local ret = capstone.cs_open(CS_ARCH_X86, CS_MODE_64, handle)
    if ret ~= 0 then
        return nil, "Capstone init failed"
    end
    
    local insn_ptr = ffi.new("cs_insn*[1]")
    
    local num = capstone.cs_disasm(handle[0], c_bytes, byte_count, 
                                   address, count or 0, insn_ptr)
    
    if num == 0 then
        capstone.cs_close(handle)
        return nil, "No instructions decoded"
    end
    
    local result = {}
    local num_insns = tonumber(num)  -- CRITICAL: convert to Lua number
    
    for i = 0, num_insns - 1 do
        local insn = insn_ptr[0][i]
        
        local hex_bytes = {}
        for j = 0, tonumber(insn.size) - 1 do
            table.insert(hex_bytes, string.format("%02X", insn.bytes[j]))
        end
        
        table.insert(result, {
            address = tonumber(insn.address),
            mnemonic = ffi.string(insn.mnemonic),
            operands = ffi.string(insn.op_str),
            size = tonumber(insn.size),
            bytes = table.concat(hex_bytes, " ")
        })
    end
    
    capstone.cs_free(insn_ptr[0], num)
    capstone.cs_close(handle)
    
    return result
end

function M.test()
    local test_bytes = {0x48, 0xC7, 0xC0, 0x34, 0x12, 0x00, 0x00}
    local insns, err = M.disassemble(test_bytes, 0x400000, 1)
    
    if not insns then
        print("[-] Test failed: " .. tostring(err))
        return false
    end
    
    print("[+] Capstone working!")
    print(string.format("    0x%X: %s %s", 
        insns[1].address, insns[1].mnemonic, insns[1].operands))
    return true
end

return M
