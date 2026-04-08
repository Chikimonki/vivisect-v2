#!/usr/bin/env luajit
-- find_function.lua
-- Locate a function in a running process

local ffi = require("ffi")

local function read_maps(pid)
    local f = io.open(string.format("/proc/%d/maps", pid), "r")
    if not f then error("Cannot read /proc/" .. pid .. "/maps") end
    
    local maps = {}
    for line in f:lines() do
        -- Parse: 7f1234567000-7f1234568000 r-xp ... /lib/libc.so.6
        local addr_start, addr_end, perms, path = line:match("(%x+)%-(%x+)%s+([rwxp-]+)%s+%x+%s+%x+:%x+%s+%d+%s+(.*)")
        if addr_start and perms:match("r.x") then  -- Executable region
            table.insert(maps, {
                start = tonumber(addr_start, 16),
                finish = tonumber(addr_end, 16),
                perms = perms,
                path = path:match("^%s*(.-)%s*$") or ""
            })
        end
    end
    f:close()
    return maps
end

local function find_libc(pid)
    local maps = read_maps(pid)
    for _, map in ipairs(maps) do
        if map.path:match("libc%.so") or map.path:match("libc%-") then
            print(string.format("[+] Found libc at: 0x%X - 0x%X", map.start, map.finish))
            print(string.format("    Path: %s", map.path))
            return map.start, map.path
        end
    end
    error("libc not found in process")
end

local function get_strcmp_offset(libc_path)
    -- Use readelf to find strcmp offset in libc
    local handle = io.popen(string.format("readelf -s %s | grep strcmp", libc_path))
    local output = handle:read("*a")
    handle:close()

    if output == "" then
        error("No strcmp symbol found in " .. libc_path)
    end

    -- Try multiple patterns
    local offset = output:match("%s+%d+:%s+(%x+)%s+%d+%s+I?FUNC")

    if not offset then
        print("[-] Pattern match failed. Raw output:")
        print(output)
        print("[-] Trying alternative extraction...")
        --Extract just the hex offset (second field after the colon)
        offset = output:match(":%s+(%x+)")
    end
    
    if not offset then
        error("Could not parse strcmp offset from readelf")
    end
    return tonumber(offset, 16)
end

-- Main
local pid = tonumber(arg[1])
if not pid then
    print("Usage: luajit find_function.lua <pid>")
    os.exit(1)
end

print(string.format("[*] Searching for strcmp in PID %d", pid))

local libc_base, libc_path = find_libc(pid)
local strcmp_offset = get_strcmp_offset(libc_path)

print(string.format("[+] strcmp offset in libc: 0x%X", strcmp_offset))

local strcmp_addr = libc_base + strcmp_offset
print(string.format("[+] strcmp address in process: 0x%X", strcmp_addr))
print(string.format("\n[*] Use this address for inline hooking"))