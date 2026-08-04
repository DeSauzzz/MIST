TOOLCHAIN := riscv64-unknown-elf
STARTDIR := .

BUILDDIR := $(STARTDIR)/sw/tests/asm
LINKER := $(STARTDIR)/sw/ld-startup/linker.ld
ISA ?= rv32i
TARGET ?= instr_56

asmconv:
	mkdir -p $(STARTDIR)/build && \
	$(TOOLCHAIN)-as -march=$(ISA) $(BUILDDIR)/$(TARGET).S -o $(BUILDDIR)/$(TARGET).o && \
	$(TOOLCHAIN)-ld -m elf32lriscv  -T $(LINKER) $(BUILDDIR)/$(TARGET).o -o $(BUILDDIR)/$(TARGET).elf && \
	$(TOOLCHAIN)-objdump -d $(BUILDDIR)/$(TARGET).elf > $(BUILDDIR)/$(TARGET).dis && \
	$(TOOLCHAIN)-objcopy -O binary $(BUILDDIR)/$(TARGET).elf $(BUILDDIR)/$(TARGET).bin && \
	mv $(BUILDDIR)/$(TARGET).o $(STARTDIR)/build && mv $(BUILDDIR)/$(TARGET).elf $(STARTDIR)/build && \
	mv $(BUILDDIR)/$(TARGET).dis $(STARTDIR)/build && mv $(BUILDDIR)/$(TARGET).bin $(STARTDIR)/build

bin2hex:
	@test -d "$(STARTDIR)/build" || { \
		echo "build directory doesn't exist"; \
		exit 1; \
	}
	@test -f "$(STARTDIR)/build/$(TARGET).bin" || { \
		echo "Binary file doesn't exist"; \
		exit 1; \
	}
	mkdir -p $(STARTDIR)/mem_files && \
	xxd -p -c 4 $(STARTDIR)/build/$(TARGET).bin | \
	sed 's/\(..\)\(..\)\(..\)\(..\)/\4\3\2\1/' > $(STARTDIR)/build/$(TARGET).dat && \
	mv $(STARTDIR)/build/$(TARGET).dat $(STARTDIR)/mem_files

spike-sim:
	@cd build && \
	spike -l --isa=$(ISA) $(TARGET).elf

clean:
	rm -rf $(STARTDIR)/build && \
	rm -rf $(STARTDIR)/mem_files
