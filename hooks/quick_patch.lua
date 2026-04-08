#!/usr/bin/env luajit
-- ~/vivisect/hooks/quick_patch.lua
-- Patch authentication without Python, venvs, or regret

local ffi = require("ffi")

ffi.cdef[[
    typedef struct { int _; } FILE;
    FILE *fopen(const char *path, const char *mode);
    size_t fread(void *ptr, size_t size, size_t nmemb, FILE *stream);
    size_t fwrite(const void *ptr, size_t size, size_t nmemb, FILE *stream);
    int fseek(FILE *stream, long offset, int whence);
    long ftell(FILE *stream);
    int fclose(FILE *stream);
    void *malloc(size_t size);
    void *memcpy(void *dest, const void *src, size_t n);
]]

local SEEK_SET, SEEK_END = 0, 2

local function read_file(path)
    local f = ffi.C.fopen(path, "rb")
    if f == nil then error("Cannot open: " .. path) end
    
    ffi.C.fseek(f, 0, SEEK_END)
    local size = ffi.C.ftell(f)
    ffi.C.fseek(f, 0, SEEK_SET)
    
    local buf = ffi.cast("uint8_t*", ffi.C.malloc(size))
    ffi.C.fread(buf, 1, size, f)
    ffi.C.fclose(f)
    
    return buf, size
end

local function write_file(path, buf, size)
    local f = ffi.C.fopen(path, "wb")
    if f == nil then error("Cannot write: " .. path) end
    ffi.C.fwrite(buf, 1, size, f)
    ffi.C.fclose(f)
end

local function patch_auth(input, output)
    local buf, size = read_file(input)
    
    -- Search for 'test eax, eax; je' pattern (85 C0 74)
    local found = false
    for i = 0, size - 3 do
        if buf[i] == 0x85 and buf[i+1] == 0xC0 and buf[i+2] == 0x74 then
            print(string.format("[*] Found auth branch at offset 0x%X", i))
            print(string.format("    Before: %02X %02X %02X %02X", 
                  buf[i], buf[i+1], buf[i+2], buf[i+3]))
            
            -- NOP out the conditional jump
            buf[i+2] = 0x90  -- NOP
            buf[i+3] = 0x90  -- NOP
            
            print(string.format("    After:  %02X %02X %02X %02X", 
                  buf[i], buf[i+1], buf[i+2], buf[i+3]))
            print("[+] Patched: je -> NOP NOP")
            found = true
            break
        end
    end
    
    if not found then
        print("[-] Pattern not found. Binary may be different than expected.")
        return
    end
    
    write_file(output, buf, size)
    print(string.format("[+] Patched binary written to: %s", output))
end

local input = arg[1] or "targets/patient_zero"
local output = arg[2] or "targets/patient_zero_patched"

patch_auth(input, output)
os.execute("chmod +x " .. output)
