; ----------------------------------------------------------------------------
; loader.asm
; ----------------------------------------------------------------------------

; global stack_ptr
extern main

%include "boot.asm"
%include "gdt.asm"

[bits 32]

      global        _start
      section       .text
      STACKSIZE      equ     0x4000

_start:
      lgdt [gdtr]                 ; Load our own GDT, the GDTR of Grub may be invalid

      jmp CODE32_SEL:.setcs       ; Set CS to our 32-bit flat code selector
.setcs:
      mov ax, DATA32_SEL          ; Setup the segment registers with our flat data selector
      mov ds, ax
      mov es, ax
      mov fs, ax
      mov gs, ax
      mov ss, ax
      mov esp, stack+STACKSIZE
      push eax
      push ebx
      call main

endloop:
    hlt                         ; halt the CPU
    jmp endloop

section .bss
align 4
stack:
  resb STACKSIZE
stack_ptr: