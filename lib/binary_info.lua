-- binary_info.lua
-- Analyze ELF binaries and extract metadata

local ffi = require("ffi")

local M = {}

ffi.cdef[[
    typedef struct { int _; } FILE;
    FILE *fopen(const char *path, const char *mode);
    size_t fread(void *ptr, size_t size, size_t nmemb, FILE *stream);
    int fseek(FILE *stream, long offset, int whence);
    int fclose(FILE *stream);
    
    typedef struct {
        uint8_t  e_ident[16];
        uint16_t e_type;
        uint16_t e_machine;
        uint32_t e_version;
        uint64_t e_entry;
        uint64_t e_phoff;
        uint64_t e_shoff;
    } Elf64_Ehdr;
]]

function M.read_elf_header(path)
    local f = ffi.C.fopen(path, "rb")
    if f == nil then return nil, "Cannot open file" end
    
    local hdr = ffi.new("Elf64_Ehdr")
    ffi.C.fread(hdr, ffi.sizeof(hdr), 1, f)
    ffi.C.fclose(f)
    
    -- Verify ELF magic
    if hdr.e_ident[0] ~= 0x7F or hdr.e_ident[1] ~= string.byte('E') then
        return nil, "Not an ELF file"
    end
    
    return {
        type = tonumber(hdr.e_type),
        machine = tonumber(hdr.e_machine),
        entry = tonumber(hdr.e_entry)
    }
end

function M.is_pie(path)
    local info = M.read_elf_header(path)
    return info and info.type == 3  -- ET_DYN
end

function M.is_static(path)
    local handle = io.popen("file " .. path)
    local output = handle:read("*a")
    handle:close()
    return output:match("statically linked") ~= nil
end

function M.has_symbols(path)
    local handle = io.popen("nm " .. path .. " 2>&1")
    local output = handle:read("*a")
    handle:close()
    return not output:match("no symbols")
end

function M.find_function_plt(path, func_name)
    local handle = io.popen(string.format("objdump -d %s 2>/dev/null | grep '%s@plt>:'", path, func_name))
    local output = handle:read("*a")
    handle:close()
    
    local addr = output:match("(%x+)%s+<" .. func_name .. "@plt")
    if addr then
        return tonumber(addr, 16)
    end
    return nil
end

function M.analyze(path)
    local info = {
        path = path,
        exists = false,
        is_elf = false,
        is_pie = false,
        is_static = false,
        has_symbols = false,
        entry_point = 0
    }
    
    local f = io.open(path, "r")
    if not f then return info end
    f:close()
    info.exists = true
    
    local elf = M.read_elf_header(path)
    if elf then
        info.is_elf = true
        info.entry_point = elf.entry
    end
    
    info.is_pie = M.is_pie(path)
    info.is_static = M.is_static(path)
    info.has_symbols = M.has_symbols(path)
    
    return info
end

return M
