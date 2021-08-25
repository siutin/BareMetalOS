// modify based on:
// https://wiki.osdev.org/Bare_Bones
// https://stackoverflow.com/questions/37618111/keyboard-irq-within-an-x86-kernel/37635449#37635449
// https://www.gnu.org/software/grub/manual/multiboot2/multiboot.html#multiboot2_002eh

#include "main.h"
#include "keyboard_map.h"

void keyboard_handler(void)
{
    signed char keycode;

    keycode = read_port(0x60);
    /* Only print characters on keydown event that have
     * a non-zero mapping */
    if(keycode >= 0 && keyboard_map[keycode]) {
        terminal_putchar(keyboard_map[keycode]);
    }

    /* Send End of Interrupt (EOI) to master PIC */
    write_port(0x20, 0x20);
}

int main( unsigned int addr, unsigned long magic) {

  /* Initialize terminal interface */
  terminal_initialize();
  printf("BareMetal OS %s %s\n", "Hello", "World");

  printf("magic=0x%p\n", magic);

  if (addr & 7) {
    printf("Unaligned mbi=0x%p\n", addr);
    return -1;
  }
  
  while(1) __asm__("hlt\n\t");
  return 0;
}
