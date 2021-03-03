; ----------------------------------------------------------------------------
; loader.asm
; ----------------------------------------------------------------------------

%include "boot.asm"

[bits 32]

      global        _start
      section       .text
_start:
      EXTERN main
      call main
      hlt