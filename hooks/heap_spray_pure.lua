#!/usr/bin/env luajit
-- heap_spray_pure.lua - Heap spray using pure LuaJIT FFI

local ffi = require("ffi")

ffi.cdef[[
    void *malloc(size_t size);
    void free(void *ptr);
    void *memcpy(void *dest, const void *src, size_t n);
]]

local function spray_heap(size, count)
    print(string.format("[*] Spraying heap with %d allocations of %d bytes", count, size))
    
    local chunks = {}
    
    for i = 1, count do
        local chunk = ffi.C.malloc(size)
        if chunk ~= nil then
            -- Fill with pattern
            local pattern = string.rep("A", size)
            ffi.C.memcpy(chunk, pattern, size)
            table.insert(chunks, chunk)
        end
    end
    
    print(string.format("[+] Allocated %d chunks", #chunks))
    
    return chunks
end

-- Test
local chunks = spray_heap(64, 1000)

print("[*] Heap sprayed successfully!")
print("[*] First chunk at: " .. tostring(chunks[1]))
