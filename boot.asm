; ----------------------------------------------------------------------------
; boot.asm
; ----------------------------------------------------------------------------

section .multiboot_header
header_start:
      dd            0xe85250d6                ; multiboot v2 magic number
      dd            0                         ; architecture 0
      dd            header_end - header_start ; header length
      
      ; checksum
      dd            0x100000000 - (0xe85250d6 + 0 + (header_end - header_start))
      
      ; required end tag
      dw            0 ; type
      dw            0 ; flags
      dd            8 ; size

header_end:

[bits 32]

      global        _start
      section       .text


_start:
      mov dword [0xb8000], 0x0e650e48
      mov dword [0xb8004], 0x0e6c0e6c
      mov dword [0xb8008], 0x00000e6f
      hlt