#ifndef MIST_RISCV_TEST_H
#define MIST_RISCV_TEST_H

#define TESTNUM gp
#define MIST_RESULT_ADDR 0x20008

#define RVTEST_RV32U .macro init; .endm
#define RVTEST_RV64U RVTEST_RV32U

#define INIT_REG \
  li x1, 0; li x2, 0; li x3, 0; li x4, 0; li x5, 0; li x6, 0; li x7, 0; li x8, 0; \
  li x9, 0; li x10, 0; li x11, 0; li x12, 0; li x13, 0; li x14, 0; li x15, 0; li x16, 0; \
  li x17, 0; li x18, 0; li x19, 0; li x20, 0; li x21, 0; li x22, 0; li x23, 0; li x24, 0; \
  li x25, 0; li x26, 0; li x27, 0; li x28, 0; li x29, 0; li x30, 0; li x31, 0;

#define RVTEST_CODE_BEGIN \
  .section .text.init; \
  .align 2; \
  .globl _start; \
  _start: \
  INIT_REG

#define RVTEST_CODE_END \
  1: j 1b;

#define RVTEST_PASS \
  li t0, MIST_RESULT_ADDR; \
  li t1, 1; \
  sw t1, 0(t0); \
  1: j 1b;

#define RVTEST_FAIL \
  li t0, MIST_RESULT_ADDR; \
  slli t1, TESTNUM, 1; \
  ori t1, t1, 1; \
  bnez TESTNUM, 2f; \
  li t1, -1; \
  1: j 1b; \
  2: sw t1, 0(t0);

#define RVTEST_DATA_BEGIN \
  .align 4; .global begin_signature; begin_signature:

#define RVTEST_DATA_END \
  .align 4; .global end_signature; end_signature:

#endif
