#!/usr/bin/env luajit
-- ~/vivisect/hooks/elf_reader.lua
-- Parse an ELF binary with nothing but LuaJIT FFI
-- because importing libraries is for people who trust other humans

local ffi = require("ffi")
local bit = require("bit")

ffi.cdef[[
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

    void *malloc(size_t size);
    void free(void *ptr);
    typedef struct { int _; } FILE;
    FILE *fopen(const char *path, const char *mode);
    size_t fread(void *ptr, size_t size, size_t nmemb, FILE *stream);
    int fseek(FILE *stream, long offset, int whence);
    long ftell(FILE *stream);
    int fclose(FILE *stream);
]]

local SEEK_SET, SEEK_END = 0, 2
local SHF_EXECINSTR = 0x4

local function read_binary(path)
    local f = ffi.C.fopen(path, "rb")
    if f == nil then error("Cannot open: " .. path) end

    -- Get file size
    ffi.C.fseek(f, 0, SEEK_END)
    local size = ffi.C.ftell(f)
    ffi.C.fseek(f, 0, SEEK_SET)

    -- Read entire file into memory
    local buf = ffi.cast("uint8_t*", ffi.C.malloc(size))
    ffi.C.fread(buf, 1, size, f)
    ffi.C.fclose(f)

    return buf, size
end

local function parse_elf(path)
    local buf, size = read_binary(path)
    local ehdr = ffi.cast("Elf64_Ehdr*", buf)

    -- Validate magic
    assert(ehdr.e_ident[0] == 0x7F, "Not an ELF")
    assert(ehdr.e_ident[1] == string.byte("E"), "Not an ELF")
    assert(ehdr.e_ident[2] == string.byte("L"), "Not an ELF")
    assert(ehdr.e_ident[3] == string.byte("F"), "Not an ELF")

    print(string.format("[*] ELF Header:"))
    print(string.format("    Entry point:    0x%X", tonumber(ehdr.e_entry)))
    print(string.format("    Section headers: %d", ehdr.e_shnum))
    print(string.format("    Section size:    %d bytes each", ehdr.e_shentsize))
    print(string.format("    String table:    section %d", ehdr.e_shstrndx))

    -- Get section header string table
    local shstr_hdr = ffi.cast("Elf64_Shdr*", buf + tonumber(ehdr.e_shoff) 
                      + ehdr.e_shstrndx * ehdr.e_shentsize)
    local shstr = buf + tonumber(shstr_hdr.sh_offset)

    print(string.format("\n[*] Sections with executable code:"))
    print(string.format("    %-20s %-18s %-10s %s", "Name", "Address", "Size", "Offset"))
    print(string.format("    %-20s %-18s %-10s %s", "----", "-------", "----", "------"))

    for i = 0, ehdr.e_shnum - 1 do
        local shdr = ffi.cast("Elf64_Shdr*", buf + tonumber(ehdr.e_shoff)
                     + i * ehdr.e_shentsize)

        if bit.band(tonumber(shdr.sh_flags), SHF_EXECINSTR) ~= 0 then
            local name = ffi.string(shstr + shdr.sh_name)
            print(string.format("    %-20s 0x%016X %-10d 0x%X",
                name,
                tonumber(shdr.sh_addr),
                tonumber(shdr.sh_size),
                tonumber(shdr.sh_offset)))

            -- Dump first 32 bytes as hex
            local code = buf + tonumber(shdr.sh_offset)
            local preview_len = math.min(32, tonumber(shdr.sh_size))
            local hex = {}
            for j = 0, preview_len - 1 do
                hex[#hex + 1] = string.format("%02X", code[j])
            end
            print(string.format("    First %d bytes: %s", preview_len, 
                  table.concat(hex, " ")))
            print()
        end
    end

    ffi.C.free(buf)
end

-- Execute
local target = arg[1] or "patient_zero"
print(string.format("[*] Vivisecting: %s", target))
print(string.format("[*] Timestamp:   %s", os.date()))
print()
parse_elf(target)
print("[+] Autopsy complete. The patient did not survive.")
