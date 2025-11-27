# Makefile for AssemblyOS

# Define our assembler
AS      = nasm
# Define our linker (we won't use a separate linker for a simple boot sector, nasm handles it)
LD      = ld
# Define our disk image utility
DD      = dd

# Output file names
BOOT_BIN    = bootloader.bin
KERNEL_BIN  = kernel.bin
OS_IMG      = yannaos.img

# Source files
BOOT_SRC    = bootloader.asm
KERNEL_SRC  = kernel.asm

.PHONY: all clean run

all: $(OS_IMG)

$(BOOT_BIN): $(BOOT_SRC)
	$(AS) -f bin $< -o $@

$(KERNEL_BIN): $(KERNEL_SRC)
	$(AS) -f bin $< -o $@

$(OS_IMG): $(BOOT_BIN) $(KERNEL_BIN)
	# Create a 1.44MB floppy image, fill with zeros
	$(DD) if=/dev/zero of=$(OS_IMG) bs=1024 count=1440
	# Write the bootloader to the first sector
	$(DD) if=$(BOOT_BIN) of=$(OS_IMG) bs=512 count=1 seek=0 conv=notrunc
	# (For now, we won't load the kernel from the bootloader directly, it's just a placeholder)
	# (Later, the bootloader will read the kernel from a specific sector)
	# For demonstration, we'll just write kernel to sector 2 for now, but bootloader won't load it.
	$(DD) if=$(KERNEL_BIN) of=$(OS_IMG) bs=512 count=1 seek=1 conv=notrunc

clean:
	rm -f $(BOOT_BIN) $(KERNEL_BIN) $(OS_IMG)

run: $(OS_IMG)
	qemu-system-x86_64 -fda $(OS_IMG)