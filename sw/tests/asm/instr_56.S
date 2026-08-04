.section .text

.globl _start

_start:

addi  x1,  zero, 0x100
addi  x2,  zero, 0x200
addi  x3,  zero, 0x00A
addi  x4,  zero, 0x003
addi  x5,  zero, 0x0FF
addi  x6,  zero, 0x7FF
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
srli  x22, x20, 2
add   x23, x19, x20
sub   x24, x20, x19
and   x25, x19, x20
or    x26, x19, x20
xor   x27, x19, x20
slt   x28, x19, x20
sltu  x29, x19, x20
addi  x30, zero, 0x789
addi  x31, zero, 0x7BC
addi  x1,  zero, 0x7EF
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

end:

jal x0,end
