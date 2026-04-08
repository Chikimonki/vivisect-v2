#!/usr/bin/env luajit
-- autohook.lua
-- Universal binary hooking framework

local ffi = require("ffi")
local binary_info = require("lib.binary_info")
local hook_method = require("lib.hook_method")

ffi.cdef[[
    int fork(void);
    int execl(const char *path, const char *arg0, ...);
    long ptrace(int request, int pid, void *addr, void *data);
    int waitpid(int pid, int *status, int options);
    unsigned int sleep(unsigned int seconds);
]]

local function print_banner()
    print([[
╔══════════════════════════════════════════════╗
║  AUTOHOOK - Universal Binary Hooker         ║
║  LuaJIT + Zig + ptrace                      ║
╚══════════════════════════════════════════════╝
]])
end

local function analyze_target(path)
    print(string.format("[*] Analyzing: %s", path))
    
    local info = binary_info.analyze(path)
    
    if not info.exists then
        error("Binary not found: " .. path)
    end
    
    if not info.is_elf then
        error("Not an ELF binary")
    end
    
    print(string.format("    Entry point: 0x%X", info.entry_point))
    print(string.format("    PIE:         %s", info.is_pie and "yes" or "no"))
    print(string.format("    Static:      %s", info.is_static and "yes" or "no"))
    print(string.format("    Symbols:     %s", info.has_symbols and "yes" or "no"))
    
    return info
end

local function hook_with_preload(binary_path, func_name, implant_so)
    print("[*] Method: LD_PRELOAD")
    print(string.format("[*] Implant: %s", implant_so))
    
    local cmd = string.format("LD_PRELOAD=%s %s TESTPASSWORD", implant_so, binary_path)
    print(string.format("[*] Running: %s", cmd))
    
    local handle = io.popen(cmd .. " 2>&1")
    local output = handle:read("*a")
    handle:close()
    
    print("\n[+] Output:")
    print(output)
end

local function hook_with_plt_patch(binary_path, func_name, plt_addr)
    print("[*] Method: PLT patching")
    print(string.format("[*] Target: %s@plt at 0x%X", func_name, plt_addr))
    
    -- Fork and exec target
    print("[*] Launching target process...")
    local pid = ffi.C.fork()
    
    if pid == 0 then
        -- Child process - exec target
        ffi.C.sleep(1)  -- Give parent time to attach
        ffi.C.execl(binary_path, binary_path, "TESTPASSWORD", nil)
        os.exit(1)
    end
    
    print(string.format("[*] Target PID: %d", pid))
    ffi.C.sleep(1)
    
    -- Attach with ptrace
    print("[*] Attaching...")
    ffi.C.ptrace(16, pid, nil, nil)  -- PTRACE_ATTACH
    ffi.C.waitpid(pid, nil, 0)
    
    -- Patch PLT: xor eax,eax ; ret ; nops
    local shellcode = 0x9090909090C3C031ULL
    print(string.format("[*] Writing shellcode: 0x%016X", tonumber(shellcode)))
    ffi.C.ptrace(5, pid, ffi.cast("void*", plt_addr), ffi.cast("void*", shellcode))
    
    -- Detach
    print("[*] Detaching...")
    ffi.C.ptrace(17, pid, nil, nil)  -- PTRACE_DETACH
    
    print("[+] Hook installed - process continuing...")
    
    -- Wait for child
    ffi.C.waitpid(pid, nil, 0)
    print("[+] Process exited")
end

-- Main
local function main(args)
    print_banner()
    
    if #args < 2 then
        print("Usage: luajit autohook.lua <binary> <function> [implant.so]")
        print("\nExamples:")
        print("  luajit autohook.lua targets/patient_zero strcmp")
        print("  luajit autohook.lua /bin/ls strcmp implants/libfake_strcmp.so")
        os.exit(1)
    end
    
    local binary_path = args[1]
    local func_name = args[2]
    local implant = args[3] or "implants/libstrcmp_hook.so"
    
    -- Analyze binary
    local info = analyze_target(binary_path)
    
    -- Choose method
    local method = hook_method.choose(info, func_name)
    print(string.format("\n[*] Best method: %s", method.method))
    print(string.format("    Reason: %s", method.reason))
    
    if method.needs_root then
        print("    [!] Requires root (uses ptrace)")
    end
    
    print("")
    
    -- Execute hook
    if method.method == "LD_PRELOAD" then
        hook_with_preload(binary_path, func_name, implant)
    elseif method.method == "PLT_PATCH" then
        hook_with_plt_patch(binary_path, func_name, method.target_addr)
    else
        print("[-] Method not yet implemented: " .. method.method)
    end
end

main(arg)
