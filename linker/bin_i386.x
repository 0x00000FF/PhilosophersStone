OUTPUT_FORMAT("binary")
OUTPUT_ARCH(i386)
ENTRY(_start)

SECTIONS
{
    PROVIDE (__executable_start = 0x08048000); . = 0x08048000 + SIZEOF_HEADERS;

    .text 0x10200        :
    {
        *(.text .stub .text.* .gnu.linkonce.t.*)
    } = 0x90909090

    .rodata              : { *(.rodata .rodata.* .gnu.linkonce.r.*) }
    .rodata1             : { *(.rodata1) }

    . = ALIGN (512);
    
    .data                :
    {
        *(.data .data.* .gnu.linkonce.d.*)
        SORT(CONSTRUCTORS)
    }
    .data1               : { *(.data1) }

    __bss_start = .;
    .bss
    {
        *(.dynbss)
        *(.bss .bss.* .bnu.linkonce.b.*)
        *(COMMON)

        . = ALIGN(. != 0 ? 32 / 8 : 1)
    }

    . = ALIGN(32 / 8);
    . = ALIGN(32 / 8);

    _end = .; PROVIDE (end = .);
}
