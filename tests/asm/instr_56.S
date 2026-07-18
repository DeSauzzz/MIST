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
54: srli  x22, x20, 2
58: add   x23, x19, x20
5C: sub   x24, x20, x19
60: and   x25, x19, x20
64: or    x26, x19, x20
68: xor   x27, x19, x20
6C: slt   x28, x19, x20
70: sltu  x29, x19, x20
74: addi  x30, zero, 0x789
78: addi  x31, zero, 0xABC
7C: addi  x1,  zero, 0xDEF
80: sw    x9,  0(zero)
84: sw    x10, 4(zero)
88: sw    x11, 8(zero)
8C: sw    x12, 12(zero)
90: sw    x13, 16(zero)
94: sw    x14, 20(zero)
98: sw    x15, 24(zero)
9C: sw    x16, 28(zero)
A0: sw    x17, 32(zero)
A4: sw    x18, 36(zero)
A8: sw    x19, 40(zero)
AC: sw    x20, 44(zero)
B0: lw    x9,  0(zero)
B4: lw    x10, 4(zero)
B8: lw    x11, 8(zero)
BC: lw    x12, 12(zero)
C0: lw    x13, 16(zero)
C4: lw    x14, 20(zero)
C8: lw    x15, 24(zero)
CC: lw    x16, 28(zero)
D0: lw    x17, 32(zero)
D4: lw    x18, 36(zero)
D8: lw    x19, 40(zero)
DC: lw    x20, 44(zero)
