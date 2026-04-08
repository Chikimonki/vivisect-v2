// strcmp_hook.zig
const std = @import("std");

export fn strcmp(s1: ?[*:0]const u8, s2: ?[*:0]const u8) callconv(.C) c_int {
    _ = s1;
    _ = s2;
    
    const msg = "[Zig] strcmp() hijacked - always returning 0 (equal)\n";
    _ = std.posix.write(2, msg) catch {};
    
    return 0; // Everything is equal now
}