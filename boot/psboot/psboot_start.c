/*
 *  psboot entry : psboot_start.c 
 *  this file contains entry point and fundamental printk functionalities
 *
 */

#include <kernel/io.h>

void _start( void ) {
    printk("started psboot::_start successfully"); 
    while (1);
}
