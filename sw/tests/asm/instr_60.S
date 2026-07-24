.section .text

.globl _start

_start:

addi  x1,  zero, 0x100
addi  x2,  zero, 0x200
addi  x3,  zero, 0x00A
addi  x4,  zero, 0x003
addi  x5,  zero, 0x0FF
addi  x6,  zero, 0xF00
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
beq   x0,  x0,  12
addi  x29, zero, 0x100
addi  x30, zero, 0x200
addi  x31, zero, 0x300
bne   x1,  x2,  12
addi  x29, zero, 0x400
addi  x30, zero, 0x500
addi  x31, zero, 0x600
jal   x0,   12
addi  x29, zero, 0x700
addi  x30, zero, 0x800
addi  x31, zero, 0x900
sw    x9,  0(zero)
sw    x10, 4(zero)
sw    x11, 8(zero)
sw    x12, 12(zero)
sw    x13, 16(zero)
sw    x14, 20(zero)
sw    x15, 24(zero)
sw    x16, 28(zero)
sw    x17, 32(zero)
sw    x18, 36(zero)
sw    x19, 40(zero)
sw    x20, 44(zero)
lw    x9,  0(zero)
lw    x10, 4(zero)
lw    x11, 8(zero)
lw    x12, 12(zero)
lw    x13, 16(zero)
lw    x14, 20(zero)
lw    x15, 24(zero)
lw    x16, 28(zero)
lw    x17, 32(zero)
lw    x18, 36(zero)
lw    x19, 40(zero)
lw    x20, 44(zero)
addi  x28, zero, 0xABC
slli  x29, x28, 1
addi  x30, x29, 0x123

end:

jal x0,end
