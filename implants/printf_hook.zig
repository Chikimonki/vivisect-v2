const std = @import("std");

export fn printf(format: ?[*:0]const u8, ...) callconv(.C) c_int {
    _ = format;
    
    const msg = "[Zig] printf() hijacked - output suppressed!\n";
    _ = std.posix.write(2, msg) catch {};
    
    return 0;
}