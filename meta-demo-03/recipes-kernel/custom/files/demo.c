#include <linux/kernel.h>
#include <linux/module.h>

static int __init init_demo(void) {
	pr_info("custom_module: init module.\n");
	return 0;
}

static void __exit cleanup_demo(void) {
	pr_info("custom_module: cleanup module.\n");
}

module_init(init_demo)
module_exit(cleanup_demo)
MODULE_LICENSE("GPL");
