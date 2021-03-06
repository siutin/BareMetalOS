; ----------------------------------------------------------------------------
; loader.asm
; ----------------------------------------------------------------------------

; Paging Feature - modified from https://git.quacker.org/d/bond/

; global stack_ptr
extern main

%include "boot.asm"
%include "gdt.asm"

%define GET_P4_OFFSET(vaddr) (((vaddr) >> 39 ) & 0x1FF)
%define GET_P3_OFFSET(vaddr) (((vaddr) >> 30 ) & 0x1FF)
%define GET_P2_OFFSET(vaddr) (((vaddr) >> 21 ) & 0x1FF)

PMAP_START equ 0xFFFF900000000000
PMAP_END   equ 0xFFFF940000000000
BASE_START equ 0xFFFFFFFF80000000
BASE_END  equ 0x0000000000000000

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

      call disable_paging

      ; map P4 entry to P3. set Read/Write Flag and Present Flag
      mov dword [p4_table + GET_P4_OFFSET(0) * 8], p3_table + 11b

      ; map 4KiB entries. set Global Flag, Read/Write Flag and Present Flag
      mov dword [p3_table + GET_P3_OFFSET(0) * 8], 10000011b
      mov dword [p3_table + GET_P3_OFFSET(0) * 8 + 8], 1*1024*1024*1024 + 10000011b
      mov dword [p3_table + GET_P3_OFFSET(0) * 8 + 16], 2*1024*1024*1024 + 10000011b
      mov dword [p3_table + GET_P3_OFFSET(0) * 8 + 24], 3*1024*1024*1024 + 10000011b

      ; map first 4G to kernal pmap. set Global Flag, Read/Write Flag and Present Flag
      mov dword [p4_table + GET_P4_OFFSET(PMAP_START) * 8], p2_table + 11b

      mov dword [p2_table + GET_P3_OFFSET(PMAP_START) * 8], 10000011b
      mov dword [p2_table + GET_P3_OFFSET(PMAP_START) * 8 + 8], 1*1024*1024*1024 + 10000011b
      mov dword [p2_table + GET_P3_OFFSET(PMAP_START) * 8 + 16], 2*1024*1024*1024 + 10000011b
      mov dword [p2_table + GET_P3_OFFSET(PMAP_START) * 8 + 24], 3*1024*1024*1024 + 10000011b

      ; map first 1G to kernel base. set Read/Write Flag and Present Flag
      mov dword [p4_table + GET_P4_OFFSET(BASE_START) * 8], p1_table + 11b

      mov dword [p1_table + GET_P3_OFFSET(BASE_START) * 8], 10000011b

      call enable_paging

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

disable_paging:

    mov eax, cr0          ; Set the A-register to control register 0.
    and eax, ~(1 << 31) & 0xFFFFFFFF   ; Clear the PG-bit, which is bit 31, and hack to get rid of warning
    mov cr0, eax          ; Set control register 0 to the A-register.

    ret

enable_paging:

    ; let cr3 point at page table
    mov eax, p4_table
    mov cr3, eax

    ; enable PAE
    mov eax, cr4                 ; Set the A-register to control register 4.
    or eax, 1 << 5               ; Set the PAE-bit, which is the 6th bit (bit 5).
    mov cr4, eax                 ; Set control register 4 to the A-register.

    xchg bx, bx
    ; enable paging, enter compatibility mode
    mov eax, cr0                                   ; Set the A-register to control register 0.
    or eax, 1 << 31                                ; Set the PG-bit, which is bit 31.
    mov cr0, eax                                   ; Set control register 0 to the A-register.

    ret

section .bss
align 4
stack:
  resb STACKSIZE
stack_ptr:

section .data
align 0x1000
p4_table:
    times 0x1000 db 0

align 0x1000
p3_table:
    times 0x1000 db 0

align 0x1000
p2_table:
    times 0x1000 db 0

align 0x1000
p1_table:
    times 0x1000 db 0