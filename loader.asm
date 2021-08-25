; ----------------------------------------------------------------------------
; loader.asm
; ----------------------------------------------------------------------------

; Paging Feature - modified from https://git.quacker.org/d/bond/

; global stack_ptr
extern main

%include "boot.asm"
%include "gdt.asm"

%define GET_PADDR(x) ((x) - BASE_START)
%define GET_PML4(vaddr) (((vaddr) >> 39 ) & 0x1FF)
%define GET_PDPT(vaddr) (((vaddr) >> 30 ) & 0x1FF)
%define GET_PDE(vaddr) (((vaddr) >> 21 ) & 0x1FF)

PMAP_START   equ 0xFFFF900000000000
PMAP_END     equ 0xFFFF940000000000
BASE_START   equ 0xFFFFFFFF80000000
BASE_END     equ 0x0000000000000000
STACKSIZE    equ 0x4000

[bits 32]
global        _start
section       .text
_start:

      cli ; Clear Interrupt Flag in EFLAGS Register
      cld ; CLear Diection Flag in EFLAGS Register

      ; Push Multiboot information structure
      mov edi, ebx

      ; Push Multiboot magic value
      mov esi,eax

      mov esp, stack+STACKSIZE  ; setup stack pointer register
      mov ebp, esp


      call disable_paging

      ; map P4 entry to P3. set Read/Write Flag and Present Flag
      mov dword [GET_PADDR(pml4e) + GET_PML4(0) * 8], GET_PADDR(pdpt) + 11b

      ; map 4KiB entries. set Global Flag, Read/Write Flag and Present Flag
      mov dword [GET_PADDR(pdpt) + GET_PDPT(0) * 8], 10000011b
      mov dword [GET_PADDR(pdpt) + GET_PDPT(0) * 8 + 8], 1*1024*1024*1024 + 10000011b
      mov dword [GET_PADDR(pdpt) + GET_PDPT(0) * 8 + 16], 2*1024*1024*1024 + 10000011b
      mov dword [GET_PADDR(pdpt) + GET_PDPT(0) * 8 + 24], 3*1024*1024*1024 + 10000011b

      ; map first 4G to kernal pmap. set Global Flag, Read/Write Flag and Present Flag
      mov dword [GET_PADDR(pml4e) + GET_PML4(PMAP_START) * 8], GET_PADDR(pde) + 11b

      mov dword [GET_PADDR(pde) + GET_PDPT(PMAP_START) * 8], 10000011b
      mov dword [GET_PADDR(pde) + GET_PDPT(PMAP_START) * 8 + 8], 1*1024*1024*1024 + 10000011b
      mov dword [GET_PADDR(pde) + GET_PDPT(PMAP_START) * 8 + 16], 2*1024*1024*1024 + 10000011b
      mov dword [GET_PADDR(pde) + GET_PDPT(PMAP_START) * 8 + 24], 3*1024*1024*1024 + 10000011b

      ; map first 1G to kernel base. set Read/Write Flag and Present Flag
      mov dword [GET_PADDR(pml4e) + GET_PML4(BASE_START) * 8], GET_PADDR(pte) + 11b

      mov dword [GET_PADDR(pte) + GET_PDPT(BASE_START) * 8], 10000011b

      call enable_paging

      lgdt [gdtr64]                 ; Load our own GDT, the GDTR64 of Grub may be invalid

      jmp CODE64_SEL:start64       ; Set Segment registers to our 64-bit flat code selector

disable_paging:

    mov eax, cr0          ; Set the A-register to control register 0.
    and eax, ~(1 << 31) & 0xFFFFFFFF   ; Clear the PG-bit, which is bit 31, and hack to get rid of warning
    mov cr0, eax          ; Set control register 0 to the A-register.

    ret

enable_paging:

    ; let cr3 point at page table
    mov eax, GET_PADDR(pml4e)
    mov cr3, eax

    ; Enable extended properties
    mov eax, cr4                 ; Set the A-register to control register 4.
    or eax, 0x0000000B0          ; PGE (Bit 7), PAE (Bit 5), and PSE (Bit 4).
    mov cr4, eax                 ; Set control register 4 to the A-register.

    ; Enable long mode and SYSCALL/SYSRET
    mov ecx, 0xC0000080		; EFER MSR number
    rdmsr				; Read EFER
    or eax, 0x00000101 		; LME (Bit 8)
    wrmsr				; Write EFER

    xchg bx, bx
    ; Enable paging to activate long mode
    mov eax, cr0                                   ; Set the A-register to control register 0.
    or eax, 1 << 31                                ; Set the PG-bit, which is bit 31.
    or eax, 1 << 16
    mov cr0, eax                                   ; Set control register 0 to the A-register.

    ret
    
align 16
[BITS 64]
start64:
    mov cx, DATA64_SEL           ; Setup the segment registers with our flat data selector
    mov ds, cx
    mov es, cx
    mov fs, cx
    mov gs, cx
    mov ss, cx
    mov esp, stack+STACKSIZE  ; setup stack pointer register
    mov ebp, esp

    ; call with arguments (multiboot magic, multiboot info)
    call main wrt ..plt
    ;   mov rax, 0x2f592f412f4b2f4f
    ;   mov qword [0xb8000], rax
    hlt

endloop:
    hlt                         ; halt the CPU
    jmp endloop

section .bss
align 4
stack:
  resb STACKSIZE
stack_ptr:

section .data
align 0x1000
pml4e:
    times 0x1000 db 0

align 0x1000
pdpt:
    times 0x1000 db 0

align 0x1000
pde:
    times 0x1000 db 0

align 0x1000
pte:
    times 0x1000 db 0