OUTPUT_ARCH(riscv)
ENTRY(entry)

load = 0x0;

SECTIONS
{
    .text ALIGN(4) : AT(load)
    {
        *(.entry)
        *(.text)
        *(.text.*)

        /* Support for C++ static ctors */
        KEEP(*(SORT(.init_array.*)))
        KEEP(*(.init_array))
    }

    .rodata ALIGN(4) :
    {
        *(.rodata)
        *(.rodata.*)
        *(.srodata)
        *(.srodata.*)
    }

    .data ALIGN(4) :
    {
        *(.data)
        *(.data.*)
        *(.sdata)
        *(.sdata.*)
    }

    .bss ALIGN(4) :
    {
        *(.bss)
        *(.bss.*)
        *(.sbss)
        *(.sbss.*)
    }
}