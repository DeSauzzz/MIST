.section    .boot, "ax"

  .global _start
_start:
  la    gp, _gbl_ptr
  la    sp, _stack_top

  la    t0, _bss_start
  la    t1, _bss_end
_bss_init_loop:
  bgeu  t0, t1, _main_call
  sw    zero, 0(t0)
  addi  t0, t0, 4
  j     _bss_init_loop

_main_call:
  li    a0, 0
  li    a1, 0
  call  main

_endless_loop:
  j     _endless_loop