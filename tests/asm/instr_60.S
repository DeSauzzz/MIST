00: addi  x1,  zero, 0x100
04: addi  x2,  zero, 0x200
08: addi  x3,  zero, 0x00A
0C: addi  x4,  zero, 0x003
10: addi  x5,  zero, 0x0FF
14: addi  x6,  zero, 0xF00
18: addi  x7,  zero, 0x555
1C: addi  x8,  zero, 0x000
20: slli  x9,  x1,  2
24: srli  x10, x2,  3
28: srai  x11, x6,  4
2C: and   x12, x3,  x4
30: or    x13, x3,  x4
34: xor   x14, x5,  x6
38: add   x15, x1,  x2
3C: sub   x16, x2,  x1
40: slt   x17, x3,  x4
44: sltu  x18, x3,  x4
48: addi  x19, zero, 0x123
4C: addi  x20, zero, 0x456
50: slli  x21, x19, 1
54: beq   x0,  x0,  12
58: addi  x29, zero, 0x100
5C: addi  x30, zero, 0x200
60: addi  x31, zero, 0x300
64: bne   x1,  x2,  12
68: addi  x29, zero, 0x400
6C: addi  x30, zero, 0x500
70: addi  x31, zero, 0x600
74: jal   x0,   12
78: addi  x29, zero, 0x700
7C: addi  x30, zero, 0x800
80: addi  x31, zero, 0x900
84: sw    x9,  0(zero)
88: sw    x10, 4(zero)
8C: sw    x11, 8(zero)
90: sw    x12, 12(zero)
94: sw    x13, 16(zero)
98: sw    x14, 20(zero)
9C: sw    x15, 24(zero)
A0: sw    x16, 28(zero)
A4: sw    x17, 32(zero)
A8: sw    x18, 36(zero)
AC: sw    x19, 40(zero)
B0: sw    x20, 44(zero)
B4: lw    x9,  0(zero)
B8: lw    x10, 4(zero)
BC: lw    x11, 8(zero)
C0: lw    x12, 12(zero)
C4: lw    x13, 16(zero)
C8: lw    x14, 20(zero)
CC: lw    x15, 24(zero)
D0: lw    x16, 28(zero)
D4: lw    x17, 32(zero)
D8: lw    x18, 36(zero)
DC: lw    x19, 40(zero)
E0: lw    x20, 44(zero)
E4: addi  x28, zero, 0xABC
E8: slli  x29, x28, 1
EC: addi  x30, x29, 0x123
