#ifndef __KERNEL_IO
#define __KERNEL_IO

#include <kernel/common.h>

void _printk_typechar(const char);
void printk(const char* str, const int size);


#endif
