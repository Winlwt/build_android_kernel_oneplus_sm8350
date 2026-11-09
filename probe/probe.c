// 探测模块：在目标内核上打印 struct mm_struct 的关键字段偏移
// 加载后会立即返回 -EINVAL 自行卸载，只在 dmesg 留下结果
#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/mm_types.h>
#include <linux/sched.h>
#include <linux/sched/mm.h>

static int __init probe_init(void)
{
	pr_info("KPROBE_OFFSET mm_struct_size=%zu\n", sizeof(struct mm_struct));
	pr_info("KPROBE_OFFSET mmap=%zu\n", offsetof(struct mm_struct, mmap));
	pr_info("KPROBE_OFFSET mm_rb=%zu\n", offsetof(struct mm_struct, mm_rb));
	pr_info("KPROBE_OFFSET pgd=%zu\n", offsetof(struct mm_struct, pgd));
	pr_info("KPROBE_OFFSET mm_users=%zu\n", offsetof(struct mm_struct, mm_users));
	pr_info("KPROBE_OFFSET mm_count=%zu\n", offsetof(struct mm_struct, mm_count));
	pr_info("KPROBE_OFFSET arg_start=%zu\n", offsetof(struct mm_struct, arg_start));
	pr_info("KPROBE_OFFSET start_stack=%zu\n", offsetof(struct mm_struct, start_stack));
	pr_info("KPROBE_OFFSET task_struct_size=%zu\n", sizeof(struct task_struct));
	pr_info("KPROBE_OFFSET task_mm=%zu\n", offsetof(struct task_struct, mm));
	pr_info("KPROBE_OFFSET task_pid=%zu\n", offsetof(struct task_struct, pid));
	pr_info("KPROBE_OFFSET file_private_data=%zu\n", offsetof(struct file, private_data));
	return -EINVAL;
}

static void __exit probe_exit(void) {}

module_init(probe_init);
module_exit(probe_exit);
MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("offset probe");
