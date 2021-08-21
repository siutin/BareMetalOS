MULTIBOOT2_HEADER_MAGIC             equ 0xe85250d6
GRUB_MULTIBOOT_ARCHITECTURE_I386    equ 0x0

section .multiboot_header
align 8
header_start:
      dd            MULTIBOOT2_HEADER_MAGIC               ; multiboot v2 magic number
      dd            GRUB_MULTIBOOT_ARCHITECTURE_I386      ; architecture 0
      dd            header_end - header_start             ; header length
      
      ; checksum
      dd            0x100000000 - (MULTIBOOT2_HEADER_MAGIC + 0 + (header_end - header_start))
      
      ; required end tag
      dw            0 ; type
      dw            0 ; flags
      dd            8 ; size
header_end: