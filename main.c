// modify based on:
// https://wiki.osdev.org/Bare_Bones
// https://stackoverflow.com/questions/37618111/keyboard-irq-within-an-x86-kernel/37635449#37635449
// https://www.gnu.org/software/grub/manual/multiboot2/multiboot.html#multiboot2_002eh

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include "multiboot2.h"
#include "port_io.h"

#define IDT_SIZE 256
#define PIC_1_CTRL 0x20
#define PIC_2_CTRL 0xA0
#define PIC_1_DATA 0x21
#define PIC_2_DATA 0xA1
#include "keyboard_map.h"

void keyboard_handler_int();
void load_idt(void*);

struct idt_entry
{
    unsigned short int offset_lowerbits;
    unsigned short int selector;
    unsigned char zero;
    unsigned char flags;
    unsigned short int offset_higherbits;
} __attribute__((packed));

struct idt_pointer
{
    unsigned short limit;
    unsigned int base;
} __attribute__((packed));

struct idt_entry idt_table[IDT_SIZE];
struct idt_pointer idt_ptr;

void load_idt_entry(int isr_number, unsigned long base, short int selector, unsigned char flags)
{
    idt_table[isr_number].offset_lowerbits = base & 0xFFFF;
    idt_table[isr_number].offset_higherbits = (base >> 16) & 0xFFFF;
    idt_table[isr_number].selector = selector;
    idt_table[isr_number].flags = flags;
    idt_table[isr_number].zero = 0;
}

static void initialize_idt_pointer()
{
    idt_ptr.limit = (sizeof(struct idt_entry) * IDT_SIZE) - 1;
    idt_ptr.base = (unsigned int)&idt_table;
}

static void initialize_pic()
{
    /* ICW1 - begin initialization */
    write_port(PIC_1_CTRL, 0x11);
    write_port(PIC_2_CTRL, 0x11);

    /* ICW2 - remap offset address of idt_table */
    /*
    * In x86 protected mode, we have to remap the PICs beyond 0x20 because
    * Intel have designated the first 32 interrupts as "reserved" for cpu exceptions
    */
    write_port(PIC_1_DATA, 0x20);
    write_port(PIC_2_DATA, 0x28);

    /* ICW3 - setup cascading */
    write_port(PIC_1_DATA, 0x00);
    write_port(PIC_2_DATA, 0x00);

    /* ICW4 - environment info */
    write_port(PIC_1_DATA, 0x01);
    write_port(PIC_2_DATA, 0x01);
    /* Initialization finished */

    /* mask interrupts */
    write_port(0x21 , 0xff);
    write_port(0xA1 , 0xff);
}

void idt_init()
{
    initialize_pic();
    initialize_idt_pointer();
    load_idt(&idt_ptr);
}

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

char* itoa(unsigned int i, char b[]){
    char const digit[] = "0123456789";
    char* p = b;
    if(i<0){
        *p++ = '-';
        i *= -1;
    }
    int shifter = i;
    do{ //Move to where representation ends
        ++p;
        shifter = shifter/10;
    }while(shifter);
    *p = '\0';
    do{ //Move back, inserting digits as u go
        *--p = digit[i%10];
        i = i/10;
    }while(i);
    return b;
}

int main( unsigned int magic, unsigned long addr) {

  /* Initialize terminal interface */
  terminal_initialize();
  terminal_writestring("BareMetal OS\n");

  char str0[80];

  terminal_writestring("magic=");
  terminal_writestring(itoa(magic, str0));
  terminal_writestring("\n");

  if (addr & 7) {
    terminal_writestring("Unaligned mbi=0x");
    terminal_writehex(addr);
    terminal_writestring("\n");
    return;
  }

  unsigned size = *(unsigned *) addr;
  terminal_writestring("mbi size=0x");
  terminal_writehex(size);
  terminal_writestring("\n");

  terminal_writestring("initialize IDT ...\n");
  idt_init();
  load_idt_entry(0x21, (unsigned long) keyboard_handler_int, 0x08, 0x8e);
  terminal_writestring("initialize keyboard ...\n");
  kb_init();
  terminal_writestring("system ready ...\n");
  while(1) __asm__("hlt\n\t");
  return 0;
}
