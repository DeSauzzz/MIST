/* SPDX-License-Identifier: MIT
   Copyright (c) 2026 Artem Matyukhin */

ENTRY(_start)

MEMORY
{
  instr_mem (rx) : ORIGIN = 0x00000000, LENGTH = 64K
  data_mem  (rw) : ORIGIN = 0x00000000, LENGTH = 16K
}

SECTIONS
{
  .text :
  {
    KEEP(*(.text.init))
    *(.text .text.*)
  } > instr_mem

  .data : AT (0x80000000)
  {
    . += 16;
    *(.*data*)
    . = ALIGN(4);
  } > data_mem

  .bss (NOLOAD) :
  {
    *(.sbss .sbss.*) *(.bss .bss.*) *(COMMON)
  } > data_mem
}
