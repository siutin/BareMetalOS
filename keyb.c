#include "port_io.h"

void kb_init(void)
{
    /* This is a very basic keyboard initialization. The assumption is we have a
     * PS/2 keyboard and it is already in a proper state. This may not be the case
     * on real hardware. We simply enable the keyboard interupt */

    /* Get current master PIC interrupt mask */
    unsigned char curmask_master = read_port (0x21);

    /* 0xFD is 11111101 - enables only IRQ1 (keyboard) on master pic
       by clearing bit 1. bit is clear for enabled and bit is set for disabled */
    write_port(0x21, curmask_master & 0xFD);
}