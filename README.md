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
├── rtl/
│   ├── include/
├── sw/
│   ├── ld-startup/
│   └── verif/
|       ├── coremark
|       └── riscv-tests
├── tb/
├── .gitignore
├── .gitmodules
├── LICENSE
├── Makefile
└── README.md
```
* **img** - directory with all pictures that was used in repository;
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
