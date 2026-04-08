const std = @import("std");

export fn hooked_function() callconv(.C) c_int {
    const msg = "[Zig] Called from LuaJIT!\n";
    _ = std.posix.write(1, msg) catch {};
    return 42;
}
