; ----------------------------------------------------------------------------
; kernel.asm
; ----------------------------------------------------------------------------

%include "boot.asm"

[bits 32]

      global        _start
      section       .text


_start:
      mov dword [0xb8000], 0x0e650e48
      mov dword [0xb8004], 0x0e6c0e6c
      mov dword [0xb8008], 0x00000e6f
      hlt