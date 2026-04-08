#!/usr/bin/env luajit
package.path = package.path .. ";../lib/?.lua;./?.lua"
-- auto_pwn.lua - ABSOLUTE PATH VERSION

package.path = package.path .. ";../lib/?.lua;./?.lua"

local exploit_model = require("exploit_model")

local function auto_pwn(binary_path)
    -- Convert to absolute path
    if not binary_path:match("^/") then
        local pwd = io.popen("pwd"):read("*l")
        binary_path = pwd .. "/" .. binary_path
    end
    
    print([[
╔══════════════════════════════════════════╗
║     VIVISECT AUTO-PWN ENGINE v4.0       ║
║     [ Neural Exploit Generation ]        ║
╚══════════════════════════════════════════╝
]])
    
    print(string.format("\n[*] Phase 1: Vulnerability Discovery"))
    local vulns = exploit_model.analyze(binary_path)
    
    if #vulns == 0 then
        print("[-] No vulnerabilities found")
        return
    end
    
    print(string.format("[+] Found %d vulnerabilities\n", #vulns))
    print("[*] Phase 2: Exploit Generation")
    
    for i, vuln in ipairs(vulns) do
        local exploit = exploit_model.generate_exploit(vuln)
        local filename = string.format("exploit_%s_%d.py", vuln.type, i)
        
        local f = io.open(filename, "w")
        if f then
            f:write(exploit)
            f:close()
            print(string.format("[+] Generated: %s", filename))
        end
    end
    
    print([[

╔══════════════════════════════════════════╗
║     🎉 AUTO-PWN COMPLETE                 ║
╚══════════════════════════════════════════╝
]])
end

local target = arg[1]
if not target then
    print("Usage: luajit auto_pwn.lua <binary>")
    os.exit(1)
end

auto_pwn(target)
