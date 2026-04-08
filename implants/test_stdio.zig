const std = @import("std");

export fn hello_from_zig() callconv(.c) c_int {
    const msg = "[Zig 0.15.2] Working with LuaJIT!\n";
    _ = std.posix.write(1, msg) catch {};
    return 42;
}
