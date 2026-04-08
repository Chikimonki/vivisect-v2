const std = @import("std");
const posix = std.posix;

const PIPE_READ = 0;
const PIPE_WRITE = 1;

export fn syscall_exec(cmd_ptr: [*:0]const u8, out_buf: [*]u8, buf_size: usize) c_int {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    
    const cmd = std.mem.span(cmd_ptr);
    
    // Parse command into argv
    var argv_list = std.ArrayList([]const u8).init(allocator);
    defer argv_list.deinit();
    
    var iter = std.mem.splitScalar(u8, cmd, ' ');
    while (iter.next()) |arg| {
        if (arg.len > 0) {
            argv_list.append(arg) catch return -1;
        }
    }
    
    if (argv_list.items.len == 0) return -1;
    
    // Create pipe
    var pipe_fds: [2]posix.fd_t = undefined;
    posix.pipe(&pipe_fds) catch return -2;
    
    // Fork
    const pid = posix.fork() catch return -3;
    
    if (pid == 0) {
        // CHILD PROCESS
        
        // Redirect stdout/stderr to pipe
        posix.dup2(pipe_fds[PIPE_WRITE], posix.STDOUT_FILENO) catch {};
        posix.dup2(pipe_fds[PIPE_WRITE], posix.STDERR_FILENO) catch {};
        posix.close(pipe_fds[PIPE_READ]);
        posix.close(pipe_fds[PIPE_WRITE]);
        
        // Build null-terminated argv
        var argv_buf = allocator.alloc([*:0]const u8, argv_list.items.len + 1) catch {
            posix.exit(1);
        };
        
        for (argv_list.items, 0..) |arg, i| {
            const arg_z = allocator.dupeZ(u8, arg) catch {
                posix.exit(1);
            };
            argv_buf[i] = arg_z.ptr;
        }
        argv_buf[argv_list.items.len] = null;
        
        // Execute (no shell)
        const empty_env = [_:null]?[*:0]const u8{null};
        _ = posix.execveZ(argv_buf[0], @ptrCast(argv_buf.ptr), @ptrCast(&empty_env));
        
        // If execve returns, it failed
        posix.exit(1);
        
    } else {
        // PARENT PROCESS
        
        posix.close(pipe_fds[PIPE_WRITE]);
        
        // Read child output
        var total: usize = 0;
        while (total < buf_size - 1) {
            const n = posix.read(pipe_fds[PIPE_READ], out_buf[total..buf_size-1]) catch break;
            if (n == 0) break;
            total += n;
        }
        
        out_buf[total] = 0; // null terminate
        
        posix.close(pipe_fds[PIPE_READ]);
        
        // Wait for child
        _ = posix.waitpid(pid, 0);
        
        return @intCast(total);
    }
}
