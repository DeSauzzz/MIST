.section .text

.globl _start

_start:

addi  x1,  zero, 0x100
addi  x2,  zero, 0x200
addi  x3,  zero, 0x00A
addi  x4,  zero, 0x003
addi  x5,  zero, 0x0FF
addi  x6,  zero, 0x7FD
addi  x7,  zero, 0x555
addi  x8,  zero, 0x000
slli  x9,  x1,  2
srli  x10, x2,  3
srai  x11, x6,  4
and   x12, x3,  x4
or    x13, x3,  x4
xor   x14, x5,  x6
add   x15, x1,  x2
sub   x16, x2,  x1
slt   x17, x3,  x4
sltu  x18, x3,  x4
addi  x19, zero, 0x123
addi  x20, zero, 0x456
slli  x21, x19, 1
beq   x0,  x0,  1f
addi  x29, zero, 0x100
addi  x30, zero, 0x200
1:
addi  x31, zero, 0x300
bne   x1,  x2,  2f
addi  x29, zero, 0x400
addi  x30, zero, 0x500
2:
addi  x31, zero, 0x600
jal   x0,   3f
addi  x29, zero, 0x700
addi  x30, zero, 0x7FE
3:
addi  x31, zero, 0x7FF
lui x8, 0x80000
sw    x9,  0(x8)
sw    x10, 4(x8)
sw    x11, 8(x8)
sw    x12, 12(x8)
sw    x13, 16(x8)
sw    x14, 20(x8)
sw    x15, 24(x8)
sw    x16, 28(x8)
sw    x17, 32(x8)
sw    x18, 36(x8)
sw    x19, 40(x8)
sw    x20, 44(x8)
lw    x9,  0(x8)
lw    x10, 4(x8)
lw    x11, 8(x8)
lw    x12, 12(x8)
lw    x13, 16(x8)
lw    x14, 20(x8)
lw    x15, 24(x8)
lw    x16, 28(x8)
lw    x17, 32(x8)
lw    x18, 36(x8)
lw    x19, 40(x8)
lw    x20, 44(x8)
addi  x28, zero, 0x6BC
slli  x29, x28, 1
addi  x30, x29, 0x123

end:

jal x0, end
