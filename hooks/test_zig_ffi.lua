local ffi = require("ffi")
ffi.cdef[[ int hooked_function(void); ]]
local lib = ffi.load("../implants/libhook_test.so")
print("[LuaJIT] Calling Zig...")
local result = lib.hooked_function()
print(string.format("[LuaJIT] Zig returned: %d", result))
print("[+] FFI bridge operational!")
