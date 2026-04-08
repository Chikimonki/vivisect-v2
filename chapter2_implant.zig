// chapter2_implant.zig
const std = @import("std");
const windows = std.os.windows;

export fn Present_Hook(
    This: ?*anyopaque,
    SyncInterval: u32,
    Flags: u32
) callconv(windows.stdcall) windows.HRESULT {
    imgui_render_frame();
    return original_present.?(@ptrCast(This), SyncInterval, Flags);
}
