const std = @import("std");

export fn fake_strcmp(s1: ?[*:0]const u8, s2: ?[*:0]const u8) callconv(.C) c_int {
    _ = s1;
    _ = s2;
    
    const msg = "[GOT HIJACKED] strcmp replaced - always returning 0\n";
    _ = std.posix.write(2, msg) catch {};
    
    return 0; // Always equal
}
