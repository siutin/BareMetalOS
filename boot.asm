MULTIBOOT2_HEADER_MAGIC             equ 0xe85250d6
GRUB_MULTIBOOT_ARCHITECTURE_I386    equ 0x0

MULTIBOOT2_HEADER_TAG_OPTIONAL      equ 1

MULTIBOOT2_HEADER_TAG_END                 equ 0
MULTIBOOT2_HEADER_TAG_INFORMATION_REQUEST equ 1
MULTIBOOT2_HEADER_TAG_ADDRESS             equ 2
MULTIBOOT2_HEADER_TAG_ENTRY_ADDRESS       equ 3
MULTIBOOT2_HEADER_TAG_CONSOLE_FLAGS       equ 4
MULTIBOOT2_HEADER_TAG_FRAMEBUFFER         equ 5
MULTIBOOT2_HEADER_TAG_MODULE_ALIGN        equ 6
MULTIBOOT2_HEADER_TAG_EFI_BS              equ 7
MULTIBOOT2_HEADER_TAG_ENTRY_ADDRESS_EFI32 equ 8
MULTIBOOT2_HEADER_TAG_ENTRY_ADDRESS_EFI64 equ 9
MULTIBOOT2_HEADER_TAG_RELOCATABLE         equ 10

section .multiboot_header
align 8
header_start:
      dd            MULTIBOOT2_HEADER_MAGIC               ; multiboot v2 magic number
      dd            GRUB_MULTIBOOT_ARCHITECTURE_I386      ; architecture 0
      dd            header_end - header_start             ; header length
      
      ; checksum
      dd            0x100000000 - (MULTIBOOT2_HEADER_MAGIC + 0 + (header_end - header_start))

align 8
; FRAMEBUFFER HEADER TAG
    dw            MULTIBOOT2_HEADER_TAG_FRAMEBUFFER
    dw            MULTIBOOT2_HEADER_TAG_OPTIONAL
    dd            20
    dd            1024
    dd            768
    dd            32
    
; address_tag_start:
;       dw            2
;       dw            1
;       dd            address_tag_end - address_tag_start
;       dd            header_start  ; header_addr
;       dd            _start        ; load_addr
;       dd            _edata        ; load_end_addr
;       dd            _end          ; bss_end_addr`
; address_tag_end:

; entry_address_tag_start:
; dw            3
; dw            1
; dd            entry_address_tag_end - entry_address_tag_start
; dd            _start              ; multiboot_entry
; entry_address_tag_end:

; framebuffer_tag_start:
;       dw            5
;       dw            1
;       dd            framebuffer_tag_end - framebuffer_tag_start
;       dd            1024
;       dd            768
;       dd            32

; framebuffer_tag_end:
align 8
      ; required end tag
      dw            0 ; type
      dw            0 ; flags
      dd            8 ; size
header_end: