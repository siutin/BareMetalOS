; ----------------------------------------------------------------------------
; boot.asm
; ----------------------------------------------------------------------------

[bits 32]

      global        _start
      section       .text

%define system_call int 0x80

_start:
      mov           eax, 4                    ; system call for write
      mov           ebx, 1                    ; first arg, stdout
      mov           ecx, message              ; second arg, starting at message
      mov           edx, messageLen           ; third arg, message length
      system_call

      mov           eax, 1                    ; system call for exit
      xor           ebx, ebx                  ; first arg, exit code 0=SUCCESS
      system_call

section .data
      message       db "Hello World", 10, 0
      messageLen    equ $-message