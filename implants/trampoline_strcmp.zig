// trampoline_strcmp.zig
const std = @import("std");

// Original bytes we'll overwrite (saved for restoration)
var original_bytes: [12]u8 = undefined;
var original_strcmp: ?*const fn (?[*:0]const u8, ?[*:0]const u8) callconv(.C) c_int = null;

export fn fake_strcmp(_: ?[*:0]const u8, _: ?[*:0]const u8) callconv(.C) c_int {
    const msg = "[Trampoline] strcmp hooked!\n";
    _ = std.posix.write(2, msg) catch {};
    
    // Always return 0 (equal)
    return 0;
}

// Trampoline stub (will be injected)
export fn trampoline_stub() callconv(.Naked) void {
    // This is pure assembly - saves registers, calls fake_strcmp, returns
    asm volatile (
        \\  push %%rax
        \\  push %%rbx
        \\  push %%rcx
        \\  push %%rdx
        \\  push %%rsi
        \\  push %%rdi
        \\  push %%r8
        \\  push %%r9
        \\  push %%r10
        \\  push %%r11
        \\  
        \\  call fake_strcmp
        \\  
        \\  pop %%r11
        \\  pop %%r10
        \\  pop %%r9
        \\  pop %%r8
        \\  pop %%rdi
        \\  pop %%rsi
        \\  pop %%rdx
        \\  pop %%rcx
        \\  pop %%rbx
        \\  pop %%rax
        \\  
        \\  ret
    );
}