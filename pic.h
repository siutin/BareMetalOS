#include "port_io.h"

#define IDT_SIZE 256
#define PIC_1_CTRL 0x20
#define PIC_2_CTRL 0xA0
#define PIC_1_DATA 0x21
#define PIC_2_DATA 0xA1

struct idt_entry
{
  uint16_t    base_low;      // The lower 16 bits of the ISR's address
  uint16_t    cs;    // The GDT segment selector that the CPU will load into CS before calling the ISR
  uint8_t     ist;          // The IST in the TSS that the CPU will load into RSP; set to zero for now
  uint8_t     attributes;   // Type and attributes; see the IDT page
  uint16_t    base_mid;      // The higher 16 bits of the lower 32 bits of the ISR's address
  uint32_t    base_high;     // The higher 32 bits of the ISR's address
  uint32_t    reserved;     // Set to zero
} __attribute__((packed));

struct idt_pointer
{
  uint16_t limit;
  uint64_t base;
} __attribute__((packed));

// ---------------------------------------------------------

struct idt_entry idt_table[IDT_SIZE];
struct idt_pointer idt_ptr;

// extern void* isr_stub_table[];

// __attribute__((noreturn))
// void exception_handler(void);
// void exception_handler() {
//   *((unsigned long*)0xB8000) = 0x2f592f412f4b2f4f;
//   __asm__ volatile ("cli; hlt");
// }

// void interrupts_handler() {
//   *((unsigned long*)0xB8000) = 0x2f592f412f4b2f4f;
//   asm("hlt");
// }

// ---------------------------------------------------------

void load_idt(void*);

void load_idt_entry(uint16_t idx, uint8_t flags, void (*handler)() )
{
  idt_table[idx].attributes     = flags;
  idt_table[idx].cs             = 0x08;
  idt_table[idx].ist            = 0;

  idt_table[idx].base_low = (uint16_t) ((uint64_t)handler&0xFFFF);
  idt_table[idx].base_mid = (uint16_t) ((uint64_t)handler >> 16);
  idt_table[idx].base_high = (uint32_t)((uint64_t)handler>> 32);

  idt_table[idx].reserved        = 0x0;
}

static void initialize_idt_pointer()
{
  idt_ptr.base = (uint64_t)&idt_table[0];
  idt_ptr.limit = sizeof(struct idt_entry) * IDT_SIZE - 1;
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
    write_port(PIC_1_DATA , 0xFF);
    write_port(PIC_2_DATA , 0xFF);
}

void idt_init()
{
    initialize_pic();

    int i = 0;
    while (i < IDT_SIZE)
    {
      idt_table[i].attributes = 0;
      idt_table[i].ist = 0;
      idt_table[i].cs = 0;
      idt_table[i].base_low = 0;
      idt_table[i].base_mid = 0;
      idt_table[i].base_high = 0;
      idt_table[i].reserved = 0;
      i++;
    }

    initialize_idt_pointer();
    load_idt(&idt_ptr);

    // Enable all interrupts
    __asm__ volatile("sti");
}