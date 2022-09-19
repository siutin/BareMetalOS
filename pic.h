#include "port_io.h"

#define IDT_BASE                    0x00001000
#define VM_PML4                     0x00002000
#define VM_PDP                      0x00003000
#define MEMORY_MAP                  0x00005000
#define LOADER_DATA                 0x00006000
#define VGA_TEXT_BASE               ((volatile u16 *)0x000b8000)

#define VM_PD                       0x00010000
#define KERNEL_STACK                0x00020000  // 4k per CPU (up to 0x00030000 for 16 cpus)
#define KERNEL_BASE                 0x00100000

#define MEM_START                   0x00200000


#define IDT_SIZE 256
#define PIC_1_CTRL 0x20
#define PIC_2_CTRL 0xA0
#define PIC_1_DATA 0x21
#define PIC_2_DATA 0xA1

typedef struct IdtDesc
{
  uint16_t limit;
  uint64_t base;
} __attribute__((__packed__)) IdtDesc;

typedef struct IdtEntry
{
  uint16_t    base_low;      // The lower 16 bits of the ISR's address
  uint16_t    cs;    // The GDT segment selector that the CPU will load into CS before calling the ISR
  uint8_t     ist;          // The IST in the TSS that the CPU will load into RSP; set to zero for now
  uint8_t     attributes;   // Type and attributes; see the IDT page
  uint16_t    base_mid;      // The higher 16 bits of the lower 32 bits of the ISR's address
  uint32_t    base_high;     // The higher 32 bits of the ISR's address
  uint32_t    reserved;     // Set to zero
} __attribute__((__packed__)) IdtEntry;

// ---------------------------------------------------------

// void load_idt(void*);

static void IdtSetEntry(uint8_t idx, uint8_t flags, void (*handler)() )
{
  IdtEntry *entry = (IdtEntry *)IDT_BASE + idx;

  entry->attributes     = flags;
  entry->cs             = 0x08;
  entry->ist            = 0;

  entry->base_low = (uint16_t) ((uint64_t)handler & 0xFFFF);
  entry->base_mid = (uint16_t) ((uint64_t)handler >> 16);
  entry->base_high = (uint32_t)((uint64_t)handler >> 32);

  entry->reserved        = 0x0;
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

    /* ICW3 -  master/slave wiring */
    write_port(PIC_1_DATA, 0x04);
    write_port(PIC_2_DATA, 0x02);

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

    // int i = 0;
    // while (i < IDT_SIZE)
    // {
    //   idt_table[i].attributes = 0;
    //   idt_table[i].ist = 0;
    //   idt_table[i].cs = 0;
    //   idt_table[i].base_low = 0;
    //   idt_table[i].base_mid = 0;
    //   idt_table[i].base_high = 0;
    //   idt_table[i].reserved = 0;
    //   i++;
    // }

  IdtDesc idtDesc = {
    .limit = 256 * sizeof(IdtEntry) - 1,
    .base = IDT_BASE
  };
   __asm__ volatile("lidt %0" : : "m" (idtDesc) : "memory");
  // load_idt(&idtDesc);

    // Enable all interrupts
    __asm__ volatile("sti");
}