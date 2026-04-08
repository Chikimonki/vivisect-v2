#!/usr/bin/env luajit
-- network/scanner.lua - TCP port scanner

local ffi = require("ffi")
local socket = require("socket")

local function scan_port(host, port, timeout)
    local sock = socket.tcp()
    sock:settimeout(timeout or 0.5)
    
    local result = sock:connect(host, port)
    sock:close()
    
    return result ~= nil
end

local function scan_host(host, start_port, end_port)
    print(string.format("[*] Scanning %s (%d-%d)", host, start_port, end_port))
    
    local open_ports = {}
    
    for port = start_port, end_port do
        if scan_port(host, port) then
            table.insert(open_ports, port)
            print(string.format("[+] Port %d OPEN", port))
        end
        
        -- Progress every 100 ports
        if port % 100 == 0 then
            io.write(string.format("\r[*] Scanned %d/%d ports", port, end_port))
            io.flush()
        end
    end
    
    print(string.format("\n[+] Found %d open ports on %s", #open_ports, host))
    return open_ports
end

-- Main
local host = arg[1] or "127.0.0.1"
local start_port = tonumber(arg[2]) or 1
local end_port = tonumber(arg[3]) or 1024

print([[
╔══════════════════════════════════════════╗
║     VIVISECT NETWORK SCANNER v1.0       ║
╚══════════════════════════════════════════╝
]])

local open = scan_host(host, start_port, end_port)

if #open > 0 then
    print("\n[+] Open ports:")
    for _, port in ipairs(open) do
        local service = ({
            [21] = "FTP",
            [22] = "SSH",
            [23] = "Telnet",
            [25] = "SMTP",
            [53] = "DNS",
            [80] = "HTTP",
            [443] = "HTTPS",
            [445] = "SMB",
            [3306] = "MySQL",
            [5432] = "PostgreSQL",
            [8080] = "HTTP-Alt",
            [8443] = "HTTPS-Alt",
        })[port] or "Unknown"
        
        print(string.format("    %d/tcp  %-10s  OPEN", port, service))
    end
end
