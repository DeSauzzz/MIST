TOOLCHAIN := riscv64-unknown-elf
STARTDIR := .

BUILDDIR := $(STARTDIR)/sw/tests/asm
LINKER := $(STARTDIR)/sw/ld-startup/linker.ld
ISA ?= rv32i
TARGET ?= instr_56

asm2elf:
	mkdir -p ./build && \
	$(TOOLCHAIN)-as -march=$(ISA) $(BUILDDIR)/$(TARGET).S -o $(BUILDDIR)/$(TARGET).o && \
	$(TOOLCHAIN)-ld -m elf32lriscv  -T $(LINKER) $(BUILDDIR)/$(TARGET).o -o $(BUILDDIR)/$(TARGET).elf && \
	mv $(BUILDDIR)/$(TARGET).o $(STARTDIR)/build && mv $(BUILDDIR)/$(TARGET).elf $(STARTDIR)/build

clean:
	rm -rf $(STARTDIR)/build



