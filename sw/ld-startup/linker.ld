ENTRY(_start)

MEMORY
{
    instr_mem (rw) : ORIGIN = 0x00000000, LENGTH=1k
    data_mem  (rwx): ORIGIN = 0x00000000, LENGTH=2k
}

SECTIONS
{
    .text :
    {
        . = ALIGN(4);
        _stext = .;

        PROVIDE(_start = .);
        *(.text)
        *(.text.*)

        . = ALIGN(4);
        _etext = .;
    } > instr_mem

    .rodata :
    {
        . = ALIGN(4);

        *(.rodata)
        *(.rodata.*)

        . = ALIGN(4);
    } > instr_mem

    .data : AT (0x80000000)
    {
        . = ALIGN(4);

       _sdata = .;

       *(.data)
       *(.data.*)

       _edata = .;
    } > data_mem

    .bss :
    {
        . = ALIGN(4);

        _sbss = .;

        *(.bss)
        *(.bss.*)
        *(COMMON)

        _ebss = .;

        . = ALIGN(4);
    } > data_mem

    _stack_top = ORIGIN(data_mem) + LENGTH(data_mem);
}
