RISCV_PREFIX ?= riscv64-unknown-elf-
CC      = $(RISCV_PREFIX)gcc
OBJCOPY = $(RISCV_PREFIX)objcopy
OBJDUMP = $(RISCV_PREFIX)objdump

ISA_DIR = ../../riscv-tests/isa
BUILD   = build

TESTS   = simple add addi and andi auipc beq bge bgeu blt bltu bne \
          jal jalr lb lbu lh lhu lw lui or ori sb sh sw sll slli slt \
		  slti sltiu sltu sra srai srl srli sub xor xori

CFLAGS  = -march=rv32i -mabi=ilp32 -nostdlib -nostartfiles \
          -I. -I$(ISA_DIR)/macros/scalar \
		  -T linker.ld -Wl,--no-check-sections

all: $(foreach t, $(TESTS), $(BUILD)/$(t)/instr.mem)

$(BUILD)/%/instr.mem: $(ISA_DIR)/rv32ui/%.S riscv_test.h linker.ld
	mkdir -p $(BUILD)/$*
	$(CC) $(CFLAGS) $< -o $(BUILD)/$*/test.elf
	$(OBJCOPY) -O binary -j .text $(BUILD)/$*/test.elf $(BUILD)/$*/instr.bin
	$(OBJCOPY) -O binary -j .data $(BUILD)/$*/test.elf $(BUILD)/$*/data.bin
	$(OBJDUMP) -d $(BUILD)/$*/test.elf > $(BUILD)/$*/program.dis
	xxd -p -c 4 $(BUILD)/$*/instr.bin | sed 's/\(..\)\(..\)\(..\)\(..\)/\4\3\2\1/' > $(BUILD)/$*/instr.dat
	xxd -p -c 4 $(BUILD)/$*/data.bin | sed 's/\(..\)\(..\)\(..\)\(..\)/\4\3\2\1/' > $(BUILD)/$*/data.dat

clean:
	rm -rf $(BUILD)

.PHONY: all clean
