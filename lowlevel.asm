%define COM1 0x3F8

%macro pushaq 0
    push rax      ;save current rax
    push rbx      ;save current rbx
    push rcx      ;save current rcx
    push rdx      ;save current rdx
    push rbp      ;save current rbp
    push rdi       ;save current rdi
    push rsi       ;save current rsi
    push r8        ;save current r8
    push r9        ;save current r9
    push r10      ;save current r10
    push r11      ;save current r11
    push r12      ;save current r12
    push r13      ;save current r13
    push r14      ;save current r14
    push r15      ;save current r15
%endmacro

%macro popaq 0
  pop r15         ;restore current r15
  pop r14         ;restore current r14
  pop r13         ;restore current r13
  pop r12         ;restore current r12
  pop r11         ;restore current r11
  pop r10         ;restore current r10
  pop r9         ;restore current r9
  pop r8         ;restore current r8
  pop rsi         ;restore current rsi
  pop rdi         ;restore current rdi
  pop rbp         ;restore current rbp
  pop rdx         ;restore current rdx
  pop rcx         ;restore current rcx
  pop rbx         ;restore current rbx
  pop rax         ;restore current rax
%endmacro

[BITS 64]

global divide_by_zero
global read_port
global write_port
global com1_putc
global load_idt
global general_handler_int
; global keyboard_handler_int

; extern general_handler
; extern keyboard_handler

; keyboard_handler_int:
;     pushaq
;     ; mov rdi, rsp
;     cld
;     call keyboard_handler
;     popaq
;     ; add rsp, 16
;     ; sti
;     iretq

general_handler_int:
    ; pushaq
    ; mov rdi, rsp
    ; cld
    ; call general_handler
    mov rax, 0x2f592f412f4b2f4f
    mov qword [0xb8000], rax
    ; popaq
    ; add rsp, 16
    ; sti
    iretq

divide_by_zero:
    xor rdx, rdx
    mov rax, 1
    mov rcx, 0
    div rcx
    ret

load_idt:
    lidt [rdi]
    ; sti
    ret

com1_putc:
    mov rax, rdi
    mov dx, COM1
    out dx, al
    ret

; arg: int, port number.
read_port:
    mov rdx, rdi
    in al, dx
    ret

; arg: int, (dx)port number
;      int, (al)value to write
write_port:
    mov  rdx, rdi
    mov  rax, rsi
    out  dx, al
    ret
