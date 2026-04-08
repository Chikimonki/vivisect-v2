#!/usr/bin/env luajit
-- network/fuzzer.lua - TCP protocol fuzzer

local socket = require("socket")

local function generate_payloads()
    local payloads = {}
    
    -- Buffer overflow attempts
    for i = 1, 10 do
        local size = 2^i * 100
        table.insert(payloads, {
            name = string.format("overflow_%d", size),
            data = string.rep("A", size)
        })
    end
    
    -- Format string attempts
    local fmts = {"%s%s%s%s%s", "%x%x%x%x%x", "%n%n%n%n%n", "%p%p%p%p%p"}
    for _, fmt in ipairs(fmts) do
        table.insert(payloads, {
            name = "format_" .. fmt:sub(1,2),
            data = string.rep(fmt, 50)
        })
    end
    
    -- Null bytes
    table.insert(payloads, {
        name = "null_injection",
        data = string.rep("\x00", 100)
    })
    
    -- Integer overflow
    table.insert(payloads, {
        name = "int_overflow",
        data = string.rep("\xff", 8)
    })
    
    return payloads
end

local function fuzz_target(host, port)
    print(string.format("[*] Fuzzing %s:%d", host, port))
    
    local payloads = generate_payloads()
    local crashes = {}
    
    for i, payload in ipairs(payloads) do
        io.write(string.format("\r[%d/%d] Testing: %-20s", i, #payloads, payload.name))
        io.flush()
        
        local sock = socket.tcp()
        sock:settimeout(2)
        
        local ok = sock:connect(host, port)
        if ok then
            sock:send(payload.data .. "\r\n")
            
            local response, err = sock:receive("*l")
            if not response and err == "closed" then
                table.insert(crashes, {
                    payload = payload.name,
                    size = #payload.data
                })
                print(string.format("\n[!] CRASH with %s (%d bytes)", payload.name, #payload.data))
            end
            
            sock:close()
        else
            print(string.format("\n[-] Connection refused on attempt %d", i))
            break
        end
        
        -- Small delay between attempts
        socket.sleep(0.1)
    end
    
    print(string.format("\n\n[+] Fuzzing complete: %d crashes found", #crashes))
    
    for _, crash in ipairs(crashes) do
        print(string.format("    Payload: %s (%d bytes)", crash.payload, crash.size))
    end
    
    return crashes
end

-- Main
local host = arg[1] or "127.0.0.1"
local port = tonumber(arg[2]) or 8080

print([[
╔══════════════════════════════════════════╗
║     VIVISECT PROTOCOL FUZZER v1.0       ║
╚══════════════════════════════════════════╝
]])

fuzz_target(host, port)
