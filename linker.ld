ENTRY(_start)

SECTIONS {
  . = 0x00100000;
  .boot ALIGN(0x1000) :
  {
      *(.multiboot_header)
  }  
  .text : 
  {
    *(.text)
  }
  .data :
  {
      *(.data)
  }
}