# Makefile for YannaOS

# Assembler
NASM = nasm

# Disk image utility
DD = dd

# Emulator
QEMU = qemu-system-x86_64

# Output names
BOOTLOADER_BIN = bootloader.bin
KERNEL_BIN = kernel.bin
TEST_PROGRAM_BIN = test_program.bin
OS_IMG = yannaos.img

# Default target
all: $(OS_IMG)

$(OS_IMG): $(BOOTLOADER_BIN) $(KERNEL_BIN) $(TEST_PROGRAM_BIN)
	$(DD) if=/dev/zero of=$(OS_IMG) bs=512 count=2880 # 1.44MB floppy image
	$(DD) if=$(BOOTLOADER_BIN) of=$(OS_IMG) bs=512 count=1 conv=notrunc
	$(DD) if=$(KERNEL_BIN) of=$(OS_IMG) bs=512 seek=1 count=1 conv=notrunc
	$(DD) if=$(TEST_PROGRAM_BIN) of=$(OS_IMG) bs=512 seek=2 count=1 conv=notrunc

$(BOOTLOADER_BIN): bootloader.asm
	$(NASM) $< -f bin -o $@

$(KERNEL_BIN): kernel.asm
	$(NASM) $< -f bin -o $@

$(TEST_PROGRAM_BIN): test_program.asm
	$(NASM) $< -f bin -o $@

run: $(OS_IMG)
	$(QEMU) -fda $(OS_IMG)

clean:
	rm -f $(BOOTLOADER_BIN) $(KERNEL_BIN) $(TEST_PROGRAM_BIN) $(OS_IMG)
