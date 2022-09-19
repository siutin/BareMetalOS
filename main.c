// modify based on:
// https://wiki.osdev.org/Bare_Bones
// https://stackoverflow.com/questions/37618111/keyboard-irq-within-an-x86-kernel/37635449#37635449
// https://www.gnu.org/software/grub/manual/multiboot2/multiboot.html#multiboot2_002eh

#include "main.h"
#include "keyboard_map.h"

// void general_handler(void)
// {
//   *((unsigned long*)0xB8000) = 0x2f592f412f4b2f4f;
// }

// void keyboard_handler(void)
// {

//     signed char keycode;

//     keycode = read_port(0x60);
//     /* Only print characters on keydown event that have
//      * a non-zero mapping */
//     if(keycode >= 0 && keyboard_map[keycode]) {
//         terminal_putchar(keyboard_map[keycode]);
//     }

//     /* Send End of Interrupt (EOI) to master PIC */
//     write_port(0x20, 0x20);
// }

void divzero_init(void)
{
    unsigned char curmask_master = read_port(0x21);
    write_port(0x21, curmask_master & 0xFE);
}

int main( unsigned int addr, unsigned long magic) {

  /* Initialize terminal interface */
  terminal_initialize();
  printf("BareMetal OS -> [%d] %s\n", 0, "Init Display");
  printf("magic=0x%p\n", magic);

  com1_printf("BareMetal OS -> [%d] %s\n", 0, "Init Display");
  com1_printf("magic=0x%p\n", magic);

  if (addr & 7) {
    printf("Unaligned mbi=0x%p\n", addr);
    return -1;
  }
  
  unsigned size = *(unsigned *) addr;
  printf("Announced mbi size=0x%d\n", size);
  
  // print_multiboot_struct(addr);

  // unsigned long *buffer = 0xB8000;
  // for(unsigned short i; i < 36865; i++) {
  //   buffer[i] = 0x2f592f412f4b2f4f;
  // }

  // terminal_setpos(0,0);
  // printf("BareMetal OS - %x\n", buffer[36864]);
  
  // com1_printf("BareMetal OS - %x\n", buffer[36864]);

  terminal_setpos(0,0);
  printf("BareMetal OS -> [%d] %s", 1, "Init IDT");
  idt_init();


  com1_printf("general_handler address: %p\n", default_exception_handler);
  com1_printf("low: %x\n", ((uint64_t) default_exception_handler) & 0xFFFF);
  com1_printf("mid: %x\n", ((uint64_t) default_exception_handler) >> 16);
  com1_printf("high: %x\n", ((uint64_t) default_exception_handler) >> 32);

  // load_idt_entry(0, 0x8e00, general_handler_int);

  for (int i = 0; i < 32; ++i) {
      IdtSetEntry(i, 0x8E, default_exception_handler);
  }

  for (int i = 32; i < 256; ++i) {
      IdtSetEntry(i, 0x8F, default_interrupt_handler);
  }
  
  divzero_init();

  // IdtSetEntry(0x21, 0x8E, keyboard_handler_int);
  // terminal_setpos(0,0);
  // printf("BareMetal OS -> [%d] %s", 2, "Init Keyboard");
  // kb_init();
  // terminal_setpos(0,0);
  // printf("BareMetal OS -> [%d] %s", 3, "System Ready");

  // for (int i = 0; i < 10000; i++)
  // {
  //   for (int j = 0; j < 65535; j ++) { }
  // }
  
  // divide_by_zero();

  int result = 1/0;

  terminal_setpos(0,0);
  printf("BareMetal OS -> [%d] %s", 2, "OK               ");

  while(1) __asm__("hlt\n\t");
  return 0;
}
