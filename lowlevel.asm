%define COM1 0x3F8

[BITS 32]

section .text

extern keyboard_handler
global com1_putc
global read_port
global write_port
global load_idt
global keyboard_handler_int

keyboard_handler_int:
    pushad
    cld
    call keyboard_handler
    popad
    iretd

load_idt:
    mov edx, [esp + 4]
    lidt [edx]
    sti
    ret

; arg: int, port number.
read_port:
    mov edx, [esp + 4]
    in al, dx
    ret

; arg: int, (dx)port number
;      int, (al)value to write
write_port:
    mov   edx, [esp + 4]
    mov   al, [esp + 4 + 4]
    out   dx, al
    ret

[BITS 64]
com1_putc:
    mov rax, rdi
    mov dx, COM1
    out dx, al
    ret