#!/ur/bin/env luajit
-- ~/vivisect/hooks/test_odin_ffi.lua

local ffi = require("ffi")

ffi.cdef[[
    int hooked_function(void);
]]

-- Determine absolute path
local script_dir = debug.getinfo(1).source:match("@?(.*/)") or "./"
local lib_path = script_dir .. "../implants/libhook_test.so"

-- Verify file exists before loading
local f = io.open(lib_path, "r")
if not f then
    error("Library not found: " .. lib_path .. "\nRun: cd ~/vivisect/implants && odin build hook_test.odin -file -build-mode:shared -out:libhook_test.so")
end
f:close()

print("[LuaJIT] Loading: " .. lib_path)
local lib = ffi.load(lib_path)

print("[LuaJIT] Calling Odin function...")
local result = lib.hooked_function()
print(string.format("[LuaJIT] Odin returned: %d", result))
