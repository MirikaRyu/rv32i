OUTPUT_ARCH(riscv)
ENTRY(entry)

MEMORY
{
    ROM(rx)   : ORIGIN = 0x00000000, LENGTH = 64K
    RAM(rw)   : ORIGIN = 0x40000000, LENGTH = 512M
    IO(rw)    : ORIGIN = 0xc0000000, LENGTH = 4
}

SECTIONS
{
    .text ALIGN(4) :
    {
        *(.entry)
        *(.text)
        *(.text.*)
    }> ROM

    .rodata ALIGN(4) :
    {
        *(.rodata)
        *(.rodata.*)
        *(.srodata)
        *(.srodata.*)
        
    }> ROM

    .except ALIGN(4) :
    {
        *(.gcc_except_table)
        *(.gcc_except_table.*)

        eh_frame_start = .;

        KEEP(*(.eh_frame))
        KEEP(*SORT(.eh_frame.*))

        eh_frame_end = .;
    }> ROM

    . = ORIGIN(RAM);

    lm_data_start = LOADADDR(.data);
    .data . : 
    {
        . = ALIGN(4);

        vm_data_start = .;

        *(.data)
        *(.data.*)
        *(.sdata)
        *(.sdata.*)

        vm_data_end = .;
    }>RAM AT> ROM

    .bss . :
    {
        . = ALIGN(4);

        bss_start = .;

        *(.bss)
        *(.bss.*)
        *(.sbss)
        *(.sbss.*)
        *(COMMON)

        bss_end = .;
    }>RAM AT> ROM

    end = .;
}