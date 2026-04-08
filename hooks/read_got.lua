#!/usr/bin/env luajit
-- read_got.lua
-- Parse a binary's GOT and display all function pointers

local ffi = require("ffi")

ffi.cdef[[
    typedef struct { int _; } FILE;
    FILE *fopen(const char *path, const char *mode);
    size_t fread(void *ptr, size_t size, size_t nmemb, FILE *stream);
    int fseek(FILE *stream, long offset, int whence);
    long ftell(FILE *stream);
    int fclose(FILE *stream);
    void *malloc(size_t size);
    
    typedef struct {
        uint8_t  e_ident[16];
        uint16_t e_type;
        uint16_t e_machine;
        uint32_t e_version;
        uint64_t e_entry;
        uint64_t e_phoff;
        uint64_t e_shoff;
        uint32_t e_flags;
        uint16_t e_ehsize;
        uint16_t e_phentsize;
        uint16_t e_phnum;
        uint16_t e_shentsize;
        uint16_t e_shnum;
        uint16_t e_shstrndx;
    } Elf64_Ehdr;
    
    typedef struct {
        uint32_t sh_name;
        uint32_t sh_type;
        uint64_t sh_flags;
        uint64_t sh_addr;
        uint64_t sh_offset;
        uint64_t sh_size;
        uint32_t sh_link;
        uint32_t sh_info;
        uint64_t sh_addralign;
        uint64_t sh_entsize;
    } Elf64_Shdr;
    
    typedef struct {
        uint64_t r_offset;
        uint64_t r_info;
    } Elf64_Rel;
    
    typedef struct {
        uint64_t r_offset;
        uint64_t r_info;
        int64_t  r_addend;
    } Elf64_Rela;
]]

local function read_file(path)
    local f = ffi.C.fopen(path, "rb")
    if f == nil then error("Cannot open: " .. path) end
    
    ffi.C.fseek(f, 0, 2) -- SEEK_END
    local size = tonumber(ffi.C.ftell(f))
    ffi.C.fseek(f, 0, 0) -- SEEK_SET
    
    local buf = ffi.cast("uint8_t*", ffi.C.malloc(size))
    ffi.C.fread(buf, 1, size, f)
    ffi.C.fclose(f)
    
    return buf, size
end

local function parse_got(path)
    local buf, size = read_file(path)
    local ehdr = ffi.cast("Elf64_Ehdr*", buf)
    
    print(string.format("[*] Binary: %s", path))
    print(string.format("[*] Entry point: 0x%X", tonumber(ehdr.e_entry)))
    
    -- Get section header string table
    local shstr_hdr = ffi.cast("Elf64_Shdr*", 
        buf + tonumber(ehdr.e_shoff) + ehdr.e_shstrndx * ehdr.e_shentsize)
    local shstr = buf + tonumber(shstr_hdr.sh_offset)
    
    -- Find .got.plt section
    for i = 0, ehdr.e_shnum - 1 do
        local shdr = ffi.cast("Elf64_Shdr*", 
            buf + tonumber(ehdr.e_shoff) + i * ehdr.e_shentsize)
        local name = ffi.string(shstr + shdr.sh_name)
        
        if name == ".got.plt" then
            print(string.format("\n[+] Found .got.plt at 0x%X (size: %d bytes)", 
                tonumber(shdr.sh_addr), tonumber(shdr.sh_size)))
            
            -- Read GOT entries (each is 8 bytes / uint64_t)
            local got = ffi.cast("uint64_t*", buf + tonumber(shdr.sh_offset))
            local num_entries = tonumber(shdr.sh_size) / 8
            
            print(string.format("[*] GOT entries (%d total):", num_entries))
            for j = 0, num_entries - 1 do
                local addr = tonumber(got[j])
                if addr ~= 0 then
                    print(string.format("    [%d] 0x%016X", j, addr))
                end
            end
            
            break
        end
    end
end

local target = arg[1] or "targets/patient_zero"
parse_got(target)