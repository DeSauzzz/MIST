/* SPDX-License-Identifier: MIT
   Copyright (c) 2026 Artem Matyukhin */

ENTRY(_start)

MEMORY
{
    instr_mem (rw) : ORIGIN = 0x00000000, LENGTH = 64K
    data_mem  (rwx): ORIGIN = 0x00000000, LENGTH = 16K - 256
}

_stack_size = 2048;

SECTIONS
{
    .text :
    {
        _stext = .;

        PROVIDE(_start = .);
        *(.boot)
        *(.text .text.*)

        _etext = .;
    } > instr_mem

    .data : AT (0x80000000)
    {
        . += 16;
        _gbl_ptr = . + 2048;

       _sdata = .;

       *(.*data*)

       _edata = .;
    } > data_mem

    . = ALIGN(4);

    _bss_start = .;
    .bss :
    {

        _sbss = .;

        *(.bss .bss.*)
        *(.sbss .sbss.*)
        *(COMMON)

        _ebss = .;

    } > data_mem
    _bss_end = .;

    .stack (NOLOAD) :
    {
        . = ALIGN(16);
        . += _stack_size;
        _stack_top = .;
    } > data_mem
}
