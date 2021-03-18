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

      cli ; Clear Interrupt Flag in EFLAGS Register
      cld ; CLear Diection Flag in EFLAGS Register

      mov esp, stack+STACKSIZE  ; setup stack pointer register
      mov ebp, esp

      ; Push Multiboot information structure
      push ebx

      ; Push Multiboot magic value
      push eax

      lgdt [gdtr]                 ; Load our own GDT, the GDTR of Grub may be invalid

      jmp CODE32_SEL:.setsrs       ; Set Segment registers to our 32-bit flat code selector
.setsrs:
      mov cx, DATA32_SEL           ; Setup the segment registers with our flat data selector
      mov ds, cx
      mov es, cx
      mov fs, cx
      mov gs, cx
      mov ss, cx

      ; call with arguments (multiboot magic, multiboot info)
      call main

endloop:
    hlt                         ; halt the CPU
    jmp endloop

section .bss
align 4
stack:
  resb STACKSIZE
stack_ptr: