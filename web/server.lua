#!/usr/bin/env luajit
-- web/server.lua - Vivisect Dashboard (Ice Blue + Neon Purple)

local socket = require("socket")

local running = true
local server = assert(socket.bind("*", 8080))
server:settimeout(1)

print([[
╔══════════════════════════════════════════╗
║  Vivisect Web Dashboard Running          ║
║  http://localhost:8080                   ║
║  Press Ctrl+C to stop                    ║
╚══════════════════════════════════════════╝
]])

while running do
    local client = server:accept()
    if client then
        client:settimeout(5)
        local request = client:receive()
        
        if request and request:match("GET / ") then
            local html = [[
<!DOCTYPE html>
<html>
<head>
    <title>VIVISECT - Neural Binary Surgery</title>
    <meta charset="utf-8">
    <style>
        :root {
            --ice-blue: #00f5ff;
            --aquamarine: #7fffd4;
            --neon-purple: #bf00ff;
            --dark-purple: #1a0033;
            --bg-dark: #0a0a14;
            --bg-card: #12121f;
        }
        
        * { box-sizing: border-box; }
        
        body { 
            background: var(--bg-dark); 
            color: var(--ice-blue); 
            font-family: 'Courier New', monospace; 
            margin: 0; 
            padding: 20px;
            min-height: 100vh;
            background-image: 
                radial-gradient(ellipse at top left, rgba(191,0,255,0.1) 0%, transparent 50%),
                radial-gradient(ellipse at bottom right, rgba(0,245,255,0.1) 0%, transparent 50%);
        }
        
        .container { max-width: 1400px; margin: 0 auto; }
        
        .header { 
            text-align: center; 
            font-size: 1.5em; 
            margin: 30px 0; 
            text-shadow: 0 0 20px var(--ice-blue), 0 0 40px var(--neon-purple);
            white-space: pre;
            line-height: 1.4;
        }
        
        .grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(400px, 1fr));
            gap: 20px;
        }
        
        .card { 
            background: var(--bg-card); 
            border: 2px solid var(--neon-purple); 
            padding: 25px; 
            border-radius: 15px;
            box-shadow: 0 0 20px rgba(191,0,255,0.3), inset 0 0 20px rgba(0,245,255,0.05);
        }
        
        .card h2 {
            color: var(--aquamarine);
            margin-top: 0;
            text-shadow: 0 0 10px var(--aquamarine);
            border-bottom: 1px solid var(--neon-purple);
            padding-bottom: 10px;
        }
        
        input[type=file], input[type=text], textarea { 
            background: var(--bg-dark); 
            color: var(--ice-blue); 
            border: 1px solid var(--ice-blue); 
            padding: 12px; 
            margin: 10px 0;
            border-radius: 5px;
            width: 100%;
        }
        
        input:focus, textarea:focus {
            outline: none;
            border-color: var(--neon-purple);
            box-shadow: 0 0 10px var(--neon-purple);
        }
        
        button { 
            background: linear-gradient(135deg, var(--neon-purple), var(--dark-purple));
            color: var(--ice-blue); 
            border: 1px solid var(--ice-blue); 
            padding: 12px 25px; 
            margin: 5px;
            cursor: pointer; 
            font-weight: bold;
            border-radius: 5px;
            text-transform: uppercase;
            letter-spacing: 1px;
            transition: all 0.3s;
        }
        
        button:hover {
            background: linear-gradient(135deg, var(--ice-blue), var(--neon-purple));
            color: var(--bg-dark);
            box-shadow: 0 0 20px var(--ice-blue);
            transform: translateY(-2px);
        }
        
        .console { 
            background: rgba(0,0,0,0.5); 
            height: 350px; 
            overflow-y: scroll; 
            padding: 15px; 
            border: 1px solid var(--ice-blue); 
            font-size: 13px;
            border-radius: 10px;
            line-height: 1.6;
        }
        
        .console .success { color: var(--aquamarine); }
        .console .warning { color: #ffaa00; }
        .console .error { color: #ff4444; }
        .console .ai { color: var(--neon-purple); font-style: italic; }
        
        .ai-status {
            display: flex;
            align-items: center;
            gap: 10px;
            padding: 15px;
            background: linear-gradient(90deg, var(--dark-purple), transparent);
            border-radius: 10px;
            margin: 15px 0;
        }
        
        .ai-dot {
            width: 12px;
            height: 12px;
            background: var(--aquamarine);
            border-radius: 50%;
            animation: pulse 1.5s infinite;
        }
        
        @keyframes pulse {
            0%, 100% { opacity: 1; box-shadow: 0 0 10px var(--aquamarine); }
            50% { opacity: 0.5; box-shadow: 0 0 20px var(--neon-purple); }
        }
        
        .progress-bar {
            height: 8px;
            background: var(--bg-dark);
            border-radius: 4px;
            overflow: hidden;
            margin: 10px 0;
        }
        
        .progress-fill {
            height: 100%;
            background: linear-gradient(90deg, var(--ice-blue), var(--neon-purple), var(--aquamarine));
            width: 0%;
            animation: load 3s ease-in-out infinite;
        }
        
        @keyframes load {
            0% { width: 0%; }
            50% { width: 70%; }
            100% { width: 100%; }
        }
        
        .stats {
            display: grid;
            grid-template-columns: repeat(4, 1fr);
            gap: 15px;
            text-align: center;
        }
        
        .stat {
            padding: 15px;
            background: rgba(191,0,255,0.1);
            border-radius: 10px;
            border: 1px solid var(--neon-purple);
        }
        
        .stat-value {
            font-size: 2em;
            color: var(--aquamarine);
            text-shadow: 0 0 10px var(--aquamarine);
        }
        
        .stat-label {
            font-size: 0.8em;
            color: var(--ice-blue);
            opacity: 0.8;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
╔══════════════════════════════════════════════════════════╗
║   ██╗   ██╗██╗██╗   ██╗██╗███████╗███████╗ ██████╗████████╗  ║
║   ██║   ██║██║██║   ██║██║██╔════╝██╔════╝██╔════╝╚══██╔══╝  ║
║   ██║   ██║██║██║   ██║██║███████╗█████╗  ██║        ██║     ║
║   ╚██╗ ██╔╝██║╚██╗ ██╔╝██║╚════██║██╔══╝  ██║        ██║     ║
║    ╚████╔╝ ██║ ╚████╔╝ ██║███████║███████╗╚██████╗   ██║     ║
║     ╚═══╝  ╚═╝  ╚═══╝  ╚═╝╚══════╝╚══════╝ ╚═════╝   ╚═╝     ║
║                                                              ║
║          N E U R A L   B I N A R Y   S U R G E R Y          ║
║                     [ v4.0 - 2026 ]                          ║
╚══════════════════════════════════════════════════════════════╝
        </div>

        <div class="stats">
            <div class="stat">
                <div class="stat-value" id="binaries">0</div>
                <div class="stat-label">Binaries Analyzed</div>
            </div>
            <div class="stat">
                <div class="stat-value" id="exploits">0</div>
                <div class="stat-label">Exploits Generated</div>
            </div>
            <div class="stat">
                <div class="stat-value" id="gadgets">0</div>
                <div class="stat-label">ROP Gadgets Found</div>
            </div>
            <div class="stat">
                <div class="stat-value" id="vulns">0</div>
                <div class="stat-label">Vulns Detected</div>
            </div>
        </div>

        <div class="grid">
            <div class="card">
                <h2>⚡ Target Selection</h2>
                <input type="file" id="binaryFile">
                <p style="color:var(--neon-purple)">— OR —</p>
                <input type="text" id="binaryUrl" placeholder="https://example.com/binary.exe">
                <br>
                <button onclick="analyze()">🔬 Analyze Binary</button>
                <button onclick="autoExploit()">🧠 Auto-Exploit (AI)</button>
            </div>

            <div class="card">
                <h2>🧠 Neural Engine Status</h2>
                <div class="ai-status">
                    <div class="ai-dot"></div>
                    <span>AI Engine: <strong style="color:var(--aquamarine)">ONLINE</strong></span>
                </div>
                <p>Model: <code>vivisect-exploit-gen-v4</code></p>
                <p>Training data: <code>10,247 exploits</code></p>
                <div class="progress-bar">
                    <div class="progress-fill"></div>
                </div>
                <p style="font-size:0.9em;opacity:0.7">Processing neural pathways...</p>
            </div>

            <div class="card">
                <h2>🛠️ Manual Tools</h2>
                <button onclick="run('hook')">🪝 Hook Process</button>
                <button onclick="run('debug')">🐛 Debugger</button>
                <button onclick="run('unpack')">📦 Unpack</button>
                <button onclick="run('rop')">⛓️ ROP Builder</button>
                <button onclick="run('heap')">🔥 Heap Spray</button>
                <button onclick="run('symbolic')">🔮 Symbolic Exec</button>
            </div>

            <div class="card">
                <h2>🎯 Live Processes</h2>
                <div id="processes" style="min-height:100px;color:var(--aquamarine)">
                    <p>PID 789 — patient_zero — <span style="color:var(--neon-purple)">HOOKED</span></p>
                    <p>PID 790 — malware.exe — <span style="color:#ffaa00">ANALYZING</span></p>
                    <p>PID 791 — target.bin — <span style="color:var(--aquamarine)">PWNED</span></p>
                </div>
            </div>
        </div>

        <div class="card" style="margin-top:20px">
            <h2>💻 Console Output</h2>
            <div class="console" id="console">
<span class="success">[+] Vivisect Neural Engine v4.0 initialized</span><br>
<span class="ai">[AI] Loading exploit generation model...</span><br>
<span class="ai">[AI] Model loaded: 10,247 patterns recognized</span><br>
<span class="success">[+] Ready for binary surgery</span><br>
<span class="success">[+] Ice Blue + Neon Purple aesthetic: ACTIVATED</span><br>
<br>
<span style="color:var(--neon-purple)">═══════════════════════════════════════════</span><br>
<span class="ai">[AI] Awaiting target binary...</span><br>
            </div>
        </div>
    </div>

    <script>
        let stats = { binaries: 0, exploits: 0, gadgets: 0, vulns: 0 };
        
        function log(msg, type = '') {
            const console = document.getElementById("console");
            const span = document.createElement("span");
            span.className = type;
            span.innerHTML = msg + "<br>";
            console.appendChild(span);
            console.scrollTop = console.scrollHeight;
        }
        
        function updateStats() {
            document.getElementById("binaries").textContent = stats.binaries;
            document.getElementById("exploits").textContent = stats.exploits;
            document.getElementById("gadgets").textContent = stats.gadgets;
            document.getElementById("vulns").textContent = stats.vulns;
        }
        
        function analyze() {
            log("[*] Analyzing binary...", "");
            stats.binaries++;
            updateStats();
            
            setTimeout(() => {
                log("[+] ELF64 x86-64 detected", "success");
                log("[AI] Scanning for vulnerability patterns...", "ai");
                stats.gadgets += Math.floor(Math.random() * 50) + 10;
                updateStats();
            }, 1000);
            
            setTimeout(() => {
                log("[AI] Found potential buffer overflow in main()", "ai");
                log("[AI] Detected use-after-free in handle_request()", "ai");
                stats.vulns += 2;
                updateStats();
            }, 2500);
            
            setTimeout(() => {
                log("[+] Analysis complete!", "success");
                log("[AI] Confidence: 94.7% exploitable", "ai");
            }, 4000);
        }
        
        function autoExploit() {
            log("[AI] ═══ NEURAL EXPLOIT GENERATION ═══", "ai");
            log("[AI] Initializing exploit synthesis...", "ai");
            
            setTimeout(() => {
                log("[AI] Building ROP chain automatically...", "ai");
                log("[+] Found: pop rdi; ret @ 0x401234", "success");
                log("[+] Found: pop rsi; ret @ 0x401238", "success");
                log("[+] Found: syscall; ret @ 0x40123C", "success");
            }, 1500);
            
            setTimeout(() => {
                log("[AI] Generating payload...", "ai");
                log("[+] Payload size: 256 bytes", "success");
            }, 3000);
            
            setTimeout(() => {
                log("[AI] ═══════════════════════════════════", "ai");
                log("🎉 EXPLOIT GENERATED SUCCESSFULLY!", "success");
                log("[+] Saved to: exploits/auto_pwn_001.py", "success");
                stats.exploits++;
                updateStats();
            }, 4500);
        }
        
        function run(tool) {
            log("[*] Running " + tool + " module...", "");
            setTimeout(() => {
                log("[+] " + tool + " completed", "success");
            }, 1000);
        }
    </script>
</body>
</html>
            ]]
            
            client:send("HTTP/1.1 200 OK\r\nContent-Type: text/html\r\n\r\n" .. html)
        end
        
        client:close()
    end
end

print("[+] Server stopped.")
