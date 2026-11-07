# MIST
The development of this processor core was inspired by the "[Architectures of Computing Systems](https://github.com/MPSU/APS/tree/english_version)" (APS) course taught at MIET, as well as by an open-source core [MIRISCV](https://github.com/MPSU/MIRISCV).

## Main features
* 5-stages pipeline (Fetch, Decode, Execute, Memory, Writeback);
* Support for ISA RV32I;
* Only M-mode is supported;
* All modules are written on SystemVerilog;
* Presence of the Hazard Unit which helps with data and control hazards;
* Automated tests assembly through Makefile with using [riscv-tests](https://github.com/riscv-software-src/riscv-tests);
* Full documentation with LateX source files **(WIP)**.

## Structure of the repository
```
MIST/
├── img/
├── memory/
│   ├── coremark-performance/
│   ├── coremark-validation/
├── rtl/
│   ├── include/
├── sw/
│   ├── ld-startup/
│   └── verif/
|       ├── coremark/
|       └── riscv-tests/
├── tb/
├── .gitignore
├── .gitmodules
├── LICENSE
├── Makefile
└── README.md
```
* **img** - directory with all pictures that was used in repository;
* **memory** - directory with memory files for CoreMark run (performance and validation);
* **rtl** - modules written on SystemVerilog;
* **include** - packages used by modules from _rtl_ directory;
* **sw** - software sources;
* **ld-startup** - linker script used by MIST System;
* **verif** - verification sources;
* **coremark** - MIST platform for building CoreMark;
* **riscv-tests** -  directed tests for each instruction.

## How to build

TODO

## CoreMark

### Performance run
```bash
2K performance run parameters for coremark.
CoreMark Size    : 666
Total ticks      : 12248654
Total time (secs): 12.248654
Iterations/Sec   : 0.816416
Iterations       : 10
Compiler version : GCC16.1.0
Compiler flags   : -O2 -march=rv32i -mabi=ilp32 -ffreestanding -DPERFORMANCE_RUN=1  -nostartfiles -T ../verif/coremark//linker.ld -Wl,--no-check-sections -lc -lgcc
Memory location  : STATIC
seedcrc          : 0xe9f5
[0]crclist       : 0xe714
[0]crcmatrix     : 0x1fd7
[0]crcstate      : 0x8e3a
[0]crcfinal      : 0xfcaf
Correct operation validated. See readme.txt for run and reporting rules.
CoreMark 1.0 : 0.816416 / GCC16.1.0 -O2 -march=rv32i -mabi=ilp32 -ffreestanding -DPERFORMANCE_RUN=1  -nostartfiles -T ../verif/coremark//linker.ld -Wl,--no-check-sections -lc -lgcc / STATIC
```
### Validation run
```bash
2K validation run parameters for coremark.
CoreMark Size    : 666
Total ticks      : 13054344
Total time (secs): 13.054344
Iterations/Sec   : 0.766029
Iterations       : 10
Compiler version : GCC16.1.0
Compiler flags   : -O2 -march=rv32i -mabi=ilp32 -ffreestanding -DVALIDATION_RUN=1  -nostartfiles -T ../verif/coremark//linker.ld -Wl,--no-check-sections -lc -lgcc
Memory location  : STATIC
seedcrc          : 0x18f2
[0]crclist       : 0xe3c1
[0]crcmatrix     : 0x0747
[0]crcstate      : 0x8d84
[0]crcfinal      : 0xc64e
Correct operation validated. See readme.txt for run and reporting rules.
```
