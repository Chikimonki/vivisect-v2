const std = @import("std");

var freed_chunks: ?std.ArrayList(*anyopaque) = null;

fn get_allocator() std.mem.Allocator {
    return std.heap.page_allocator;
}

export fn free(ptr: ?*anyopaque) callconv(.C) void {
    if (ptr == null) return;
    
    const msg = "[Zig] free() hooked - memory preserved!\n";
    _ = std.posix.write(2, msg) catch {};
    
    if (freed_chunks == null) {
        freed_chunks = std.ArrayList(*anyopaque).init(get_allocator());
    }
    
    // Handle the Result from append
    freed_chunks.?.append(ptr.?) catch {};
}
