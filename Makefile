AS = nasm
LD = ld
DD = dd
QEMU = qemu-system-i386

BOOTLOADER_ASM = bootloader.asm
KERNEL_ASM = kernel.asm
TEST_PROGRAM_ASM = test_program.asm ; Keep for now, will need 32-bit adaptation later

BOOTLOADER_BIN = bootloader.bin
KERNEL_BIN = kernel.bin
TEST_PROGRAM_BIN = test_program.bin

IMAGE = yannaos.img

.PHONY: all clean run

all: $(IMAGE)

$(IMAGE): $(BOOTLOADER_BIN) $(KERNEL_BIN) $(TEST_PROGRAM_BIN)
	$(DD) if=/dev/zero of=$(IMAGE) bs=512 count=2880 # 1.44MB floppy
	$(DD) if=$(BOOTLOADER_BIN) of=$(IMAGE) bs=512 count=1 conv=notrunc
	$(DD) if=$(KERNEL_BIN) of=$(IMAGE) bs=512 seek=1 count=1 conv=notrunc # Kernel at sector 2 (LBA 1)
	$(DD) if=$(TEST_PROGRAM_BIN) of=$(IMAGE) bs=512 seek=2 count=1 conv=notrunc # Test program at sector 3 (LBA 2)

$(BOOTLOADER_BIN): $(BOOTLOADER_ASM)
	$(AS) $(BOOTLOADER_ASM) -f bin -o $(BOOTLOADER_BIN)

$(KERNEL_BIN): $(KERNEL_ASM)
	$(AS) $(KERNEL_ASM) -f bin -o $(KERNEL_BIN)

$(TEST_PROGRAM_BIN): $(TEST_PROGRAM_ASM)
	$(AS) $(TEST_PROGRAM_ASM) -f bin -o $(TEST_PROGRAM_BIN)

run: $(IMAGE)
	$(QEMU) -fda $(IMAGE) -boot a -m 16

clean:
	rm -f $(BOOTLOADER_BIN) $(KERNEL_BIN) $(TEST_PROGRAM_BIN) $(IMAGE)