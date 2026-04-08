#include <linux/bpf.h>
#include <bpf/bpf_helpers.h>
#include <linux/types.h>

struct {
    __uint(type, BPF_MAP_TYPE_ARRAY);
    __uint(max_entries, 1);
    __type(key, __u32);
    __type(value, __u64);
} hidden_pids SEC(".maps");

SEC("tracepoint/syscalls/sys_enter_kill")
int hide_pid(void *ctx) {
    __u32 key = 0;
    __u64 *pid = bpf_map_lookup_elem(&hidden_pids, &key);
    
    if (pid && *pid > 0) {
        bpf_printk("Hiding PID %llu\n", *pid);
    }
    
    return 0;
}

char LICENSE[] SEC("license") = "GPL";
