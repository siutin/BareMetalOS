; Macro to build a GDT descriptor entry

;   Name                 Offset(bits)                                         Meaning
;--------------------------------------------------------------------------------------------------------------------------------------
;        Base :  16..31, 32..39, 56..63  (32 bits)     Descriptor Base Address (Lower 4 Bytes, Middle 2 Bytes and Upper 2 Bytes)
;       Limit :  0..15, 48..51           (20 bits)     Descriptor Limit (Lower 4 Bytes, Upper 4 Bytes)
; Access Byte :  40..47                  (8 bits)      8 flags defining memory access privileges
;        Flag :  52..55                  (4 bits)      4 flags influencing segment size

%define MAKE_GDT_DESC(base, limit, access, flags) \
    (((base & 0x00FFFFFF) << 16) | \
    ((base & 0xFF000000) << 32) | \
    (limit & 0x0000FFFF) | \
    ((limit & 0x000F0000) << 32) | \
    ((access & 0xFF) << 40) | \
    ((flags & 0x0F) << 52))

section .data
align 4
gdt_start:
    dq MAKE_GDT_DESC(0, 0, 0, 0); null descriptor
gdt32_code:
    dq MAKE_GDT_DESC(0, 0x00ffffff, 10011010b, 1100b)
                                ; 32-bit code, 4kb gran, limit 0xffffffff bytes, base=0
gdt32_data:
    dq MAKE_GDT_DESC(0, 0x00ffffff, 10010010b, 1100b)
                                ; 32-bit data, 4kb gran, limit 0xffffffff bytes, base=0
end_of_gdt:

gdtr:
    dw end_of_gdt - gdt_start - 1
                                ; limit (Size of GDT - 1)
    dd gdt_start                ; base of GDT

CODE32_SEL equ gdt32_code - gdt_start
DATA32_SEL equ gdt32_data - gdt_start